/*
File: AQRecorder.mm
Abstract: n/a
Version: 2.4

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Inc. ("Apple") in consideration of your agreement to the following
terms, and your use, installation, modification or redistribution of
this Apple software constitutes acceptance of these terms.  If you do
not agree with these terms, please do not use, install, modify or
redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software.
Neither the name, trademarks, service marks or logos of Apple Inc. may
be used to endorse or promote products derived from the Apple Software
without specific prior written permission from Apple.  Except as
expressly stated in this notice, no other rights or licenses, express or
implied, are granted by Apple herein, including but not limited to any
patent rights that may be infringed by your derivative works or by other
works in which the Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

Copyright (C) 2009 Apple Inc. All Rights Reserved.
*/

#include "AQRecorder.h"


// ____________________________________________________________________________________
// Determine the size, in bytes, of a buffer necessary to represent the supplied number
// of seconds of audio data.
SInt32 AQRecorder::ComputeRecordBufferSize(const AudioStreamBasicDescription *format, double seconds)
{
	SInt32 packets, frames, bytes = 0;
	try
    {
		frames = (int)ceil(seconds * format->mSampleRate);
		
		if (format->mBytesPerFrame > 0)
        {
			bytes = frames * format->mBytesPerFrame;
        }
		else
        {
			UInt32 maxPacketSize;
			if (format->mBytesPerPacket > 0)
            {
				maxPacketSize = format->mBytesPerPacket;	// constant packet size
            }
			else
            {
				UInt32 propertySize = sizeof(maxPacketSize);
				XThrowIfError(AudioQueueGetProperty(mQueue, kAudioQueueProperty_MaximumOutputPacketSize, &maxPacketSize,
                                                        &propertySize), "couldn't get queue's maximum output packet size");
			}
			if (format->mFramesPerPacket > 0)
            {
				packets = frames / format->mFramesPerPacket;
            }
			else
            {
				packets = frames;	// worst-case scenario: 1 frame in a packet
            }
            
			if (packets == 0)		// sanity check
            {
				packets = 1;
            }
            
			bytes = packets * maxPacketSize;
		}
	}
    catch (CAXException e)
    {
		char buf[256];
		fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
		return 0;
	}

	return bytes;
}


// ____________________________________________________________________________________
// AudioQueue callback function, called when an input buffers has been filled.
void AQRecorder::MyInputBufferHandler(	void *								inUserData,
										AudioQueueRef						inAQ,
										AudioQueueBufferRef					inBuffer,
										const AudioTimeStamp *				inStartTime,
										UInt32								inNumPackets,
										const AudioStreamPacketDescription*	inPacketDesc)
{
	AQRecorder *aqr = (AQRecorder *)inUserData;

    int index = (aqr->mLastWrittenBuffer + 1) % aqr->mRecordBuffers;
                     
    if(inNumPackets > 0)
    {
        aqr->mRecordPacket += inNumPackets;
        
        memcpy((void*)aqr->mOutputBuffers[index], inBuffer->mAudioData, aqr->mBufferByteSize);
        
        // printf("mLastWrittenBuffer: %d\n", index);
        
        aqr->mLastWrittenBuffer++;

    }
/*
    else
    {
        printf("Buffer empty!!\n");
    }
*/
/*
    // if we're not stopping, re-enqueue the buffer so that it gets filled again
    if(aqr->IsRunning())
    {
        OSStatus err = AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
        if(err != noErr)
            printf("AudioQueueEnqueueBuffer error %ld\n", err);
    }
*/
}


AQRecorder::AQRecorder (CFRunLoopRef runLoop)
{
	UInt32 size;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    mRecordBuffers = [defaults integerForKey:@"Buffers"];    
    mBufferDuration = [defaults floatForKey:@"Duration"];
    
    NSLog(@"Buffer Duration: %.03f", mBufferDuration);
    NSLog(@"Buffers: %ld", mRecordBuffers);

    mIsRunning = false;
    
    // Specify the recording format
    SetupAudioFormat(kAudioFormatLinearPCM);

    // Allocate and enqueue buffers
    mBufferByteSize = ComputeRecordBufferSize(&mRecordFormat, mBufferDuration);
    mPacketsInBuffer = mBufferByteSize / mRecordFormat.mBytesPerPacket;
    NSUInteger buffersSize = mBufferByteSize * mRecordBuffers;
    printf("Buffer size:%ld - Packtes:%ld - Total size:%u\n", mBufferByteSize, mPacketsInBuffer, buffersSize);
    
    if(buffersSize > 10000000)
    {
        printf("Buffers Total size is too much.\n");

        mRecordBuffers = kNumberRecordBuffers;
        mBufferDuration = kBufferDurationSeconds;

        [defaults setInteger:mRecordBuffers forKey:@"Buffers"];
        [defaults setFloat:mBufferDuration forKey:@"Duration"];
        [defaults synchronize];
    }
    
    mBuffers = (AudioQueueBufferRef*)malloc(mRecordBuffers * sizeof(AudioQueueBufferRef));
    if(mBuffers == NULL)
        XThrowIfError(ENOMEM, "malloc(mRecordBuffers * sizeof(AudioQueueBufferRef)) failed");
    
    mOutputBuffers = (UInt16**)malloc(mRecordBuffers * sizeof(UInt16*));
    if(mOutputBuffers == NULL)
        XThrowIfError(ENOMEM, "malloc(mRecordBuffers * sizeof(UInt16*)) failed");    
    
    // create the queue
    XThrowIfError(AudioQueueNewInput(
                                     &mRecordFormat,
                                     MyInputBufferHandler,
                                     this                   /* userData */,
                                     workerRunLoop          /* run loop */,
                                     kCFRunLoopDefaultMode  /* run loop mode */,
                                     0                      /* flags */,
                                     &mQueue), "AudioQueueNewInput failed");

    size = sizeof(mRecordFormat);
    XThrowIfError(AudioQueueGetProperty(mQueue, kAudioQueueProperty_StreamDescription,
                                        &mRecordFormat, &size), "couldn't get queue's format");
        
    for(int idx = 0; idx < mRecordBuffers; ++idx)
    {
        XThrowIfError(AudioQueueAllocateBuffer(mQueue, mBufferByteSize, &mBuffers[idx]), "AudioQueueAllocateBuffer failed");
        XThrowIfError(AudioQueueEnqueueBuffer(mQueue, mBuffers[idx], 0, NULL), "AudioQueueEnqueueBuffer failed");
        
        mOutputBuffers[idx] = (UInt16*)malloc(mBufferByteSize);
        if(mOutputBuffers[idx] == NULL)
            XThrowIfError(ENOMEM, "malloc(mBufferByteSize) failed for ");
    }
}


AQRecorder::~AQRecorder ()
{
	XThrowIfError(AudioQueueStop(mQueue, true), "AudioQueueStop failed");
	XThrowIfError(AudioQueueDispose(mQueue, true), "AudioQueueDispose failed");

    free(mBuffers);
    free(mOutputBuffers);
}


void AQRecorder::SetupAudioFormat(UInt32 inFormatID)
{
	memset(&mRecordFormat, 0, sizeof(mRecordFormat));

	UInt32 size = sizeof(mRecordFormat.mSampleRate);
	XThrowIfError(AudioSessionGetProperty( kAudioSessionProperty_CurrentHardwareSampleRate, &size, 
										&mRecordFormat.mSampleRate), "couldn't get hardware sample rate");

	size = sizeof(mRecordFormat.mChannelsPerFrame);
	XThrowIfError(AudioSessionGetProperty( kAudioSessionProperty_CurrentHardwareInputNumberChannels, &size, 
										&mRecordFormat.mChannelsPerFrame), "couldn't get input channel count");
			
	mRecordFormat.mFormatID = inFormatID;
	if (inFormatID == kAudioFormatLinearPCM)
	{
		// if we want pcm, default to signed 16-bit little-endian
		mRecordFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
		mRecordFormat.mBitsPerChannel = 16;
		mRecordFormat.mBytesPerPacket = mRecordFormat.mBytesPerFrame = (mRecordFormat.mBitsPerChannel / 8) * mRecordFormat.mChannelsPerFrame;
		mRecordFormat.mFramesPerPacket = 1;
	}
}


void AQRecorder::StartRecord(void)
{
	try
    {
        mLastWrittenBuffer = -1;
        mCurReadingBuffer = -1;
		mRecordPacket = 0;
                
		// Start recording
		XThrowIfError(AudioQueueStart(mQueue, NULL), "AudioQueueStart failed");
		mIsRunning = true;
	}
	catch (CAXException &e)
    {
		char buf[256];
		fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
	}
	catch (...)
    {
		fprintf(stderr, "An unknown error occurred\n");
	}	
}


void AQRecorder::StopRecord(void)
{
    printf("mLastWrittenBuffer: %ld\n", mLastWrittenBuffer);
    printf("mCurReadingBuffer: %ld\n", mCurReadingBuffer);

    mIsRunning = false;
    
	// Stop recording
	XThrowIfError(AudioQueuePause(mQueue), "AudioQueuePause failed");	
}


UInt16* AQRecorder::NextBufferAudioData(void)
{
    if(mLastWrittenBuffer < 0)
    {
        return NULL;
    }
    
    int index = (mCurReadingBuffer + 1) % mRecordBuffers;

    if(index > mLastWrittenBuffer)
    {
        return NULL;
    }
    else
    {
        if(mLastWrittenBuffer - mCurReadingBuffer > 10)
        {
            mCurReadingBuffer = mLastWrittenBuffer - 10;
        }
        else
        {
            mCurReadingBuffer++;
        }
        
        // printf("mCurReadingBuffer: %d\n", index);

        return mOutputBuffers[index];
    }
}



