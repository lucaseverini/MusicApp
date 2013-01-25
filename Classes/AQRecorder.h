/*
 
File: AQRecorder.h
Abstract: Helper class for recording audio files via the AudioQueue
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

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <libkern/OSAtomic.h>
#import "iPublicUtility/CAStreamBasicDescription.h"
#import "iPublicUtility/CAXException.h"

#define kBufferDurationSeconds  .01             // 1/100 second
#define kNumberRecordBuffers	(1 * 1000)      // 1 second(s)

class AQRecorder 
{
public:
    AQRecorder (CFRunLoopRef workerRunLoop);
    ~AQRecorder ();
    
    UInt32						GetNumberChannels(void) const	{ return mRecordFormat.NumberChannels(); }
    AudioQueueRef				Queue(void) const				{ return mQueue; }
    CAStreamBasicDescription	DataFormat(void) const			{ return mRecordFormat; }
    
    void                        StartRecord(void);
    void                        StopRecord(void);
    Boolean                     IsRunning(void) const			{ return mIsRunning; }
    SInt32                      PacketsInBuffer(void) const		{ return mPacketsInBuffer; }
    
    UInt64                      startTime;
    
    UInt16*                     NextBufferAudioData(void);
            
private:
    AudioQueueRef				mQueue;
    AudioQueueBufferRef			*mBuffers;
    SInt64						mRecordPacket; // current packet number in record file
    CAStreamBasicDescription	mRecordFormat;
    Boolean						mIsRunning;
    SInt32                      mLastWrittenBuffer;    
    SInt32                      mCurReadingBuffer;
    SInt32                      mPacketsInBuffer;
    UInt16*                     *mOutputBuffers;
    UInt32                      mBufferByteSize;
    SInt32                      mRecordBuffers;
    float                       mBufferDuration;
    CFRunLoopRef                mWorkerRunLoop;
    
    void SetupAudioFormat(UInt32 inFormatID);
    SInt32 ComputeRecordBufferSize(const AudioStreamBasicDescription *format, double seconds);

    static void MyInputBufferHandler( void *								inUserData,
                                      AudioQueueRef                         inAQ,
                                      AudioQueueBufferRef					inBuffer,
                                      const AudioTimeStamp *				inStartTime,
                                      UInt32								inNumPackets,
                                      const AudioStreamPacketDescription*	inPacketDesc);
};
