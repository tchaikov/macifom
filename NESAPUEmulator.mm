/*
 *  NESAPUEmulator.mm
 *  Macifom
 *
 *  Created by Auston Stewart on 1/9/10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#import "NESAPUEmulator.h"

static int null_dmc_reader( void*, cpu_addr_t )
{
	return 0x55; // causes dmc sample to be flat
}

static void HandleOutputBuffer (
								void                *aqData,
								AudioQueueRef       inAQ,
								AudioQueueBufferRef inBuffer
) {
	// UInt32 bytesToRead;
	UInt32 bytesRead = 0;
	UInt32 samplesRead;
	UInt32 availableSamples;
    NESAPUState *pAqData = (NESAPUState *) aqData;
   
	NSLog(@"In HandleOutputBuffer");
	
	if (!pAqData->isRunning) {
		
		bytesRead = pAqData->bufferByteSize;
		bzero(inBuffer->mAudioData,pAqData->bufferByteSize);
		// NSLog(@"NES APU is not running. Filling buffer with zeros.");	
	}
	else {
		
		availableSamples = pAqData->blipBuffer->samples_avail();
		// NSLog(@"%d samples available from blipBuffer",availableSamples);
		samplesRead = pAqData->blipBuffer->read_samples((blip_sample_t*)inBuffer->mAudioData,pAqData->numPacketsToRead);
		bytesRead = samplesRead * 2; // As each sample is 16-bits
		// NSLog(@"%d samples read from blipBuffer",samplesRead);
		if ((availableSamples / pAqData->numPacketsToRead) > 1) pAqData->blipBuffer->remove_samples(availableSamples % pAqData->numPacketsToRead);
	}
	
	// If some data was succesfully read, enqueue the buffer
    //if (bytesRead > 0) {
		
        inBuffer->mAudioDataByteSize = bytesRead;
		AudioQueueEnqueueBuffer ( 
								 pAqData->queue,
								 inBuffer,
								 0,
								 NULL
								 );
		
		// pAqData->currentPacket += pAqData->numPacketsToRead; // assume we read as many as we wanted
        
   // } else {
		
		// FIXME: When CoreAudio stops hanging on asynchronous stops this should be uncommented
		/*
		 AudioQueueStop (pAqData->queue,false);
		 pAqData->isRunning = NO; // Stop the show if we're out of audio
		 */
    // }
}


@implementation NESAPUEmulator

- (void)initializeAudioPlaybackQueue
{
	Float32 gain = 1.0;
	int error;
	
	// Create new output
	error = AudioQueueNewOutput (
								 &(nesAPUState->dataFormat),
								 HandleOutputBuffer,
								 nesAPUState,
								 CFRunLoopGetCurrent(),
								 kCFRunLoopCommonModes,
								 0,
								 &(nesAPUState->queue)
								 );
	
	NSLog(@"AudioQueueNewOutput: %d",error);
	
	// Set buffer size
	//[self determineBufferSizeGivenMaxPacketSize:(sizeof(short)*2) andSeconds:2];
	nesAPUState->numPacketsToRead = 2940; // 44.1kHz at 60 fps = 735 plus a little wiggle room
	nesAPUState->bufferByteSize = 5880; // 735 samples times 16-bits per sample
	
	// Allocate those bufferes
	for (int i = 0; i < NUM_BUFFERS; ++i) {
		
		AudioQueueAllocateBuffer(
								 nesAPUState->queue,
								 nesAPUState->bufferByteSize,
								 &(nesAPUState->buffers[i])
								 );
		
		NSLog(@"AudioQueueAllocateBuffer: %d",error);
	}
	
	AudioQueueSetParameter (
							nesAPUState->queue,
							kAudioQueueParam_Volume,
							gain
							);
}

- (blip_time_t) clock { 

	return time += 4; 
}

- (id)init {

	if ([super init]) {
		
		time = 0;
		frame_length = 29780;
		
		nesAPU = new Nes_Apu();
		blipBuffer = new Blip_Buffer();
		blipBuffer->clock_rate( 1789773 ); // Should be 1789773 for NES
		blargg_err_t error = blipBuffer->sample_rate( 44100,300);
		if (error) NSLog(@"Error allocating blipBuffer.");
		nesAPU->dmc_reader( null_dmc_reader, NULL );
		nesAPU->output(blipBuffer);
		
		nesAPUState = (NESAPUState *)malloc(sizeof(NESAPUState));
		nesAPUState->dataFormat.mSampleRate = 44100.0;
		nesAPUState->dataFormat.mFormatID = kAudioFormatLinearPCM;
		
		// Sort out endianness
		if (NSHostByteOrder() == NS_BigEndian)
			nesAPUState->dataFormat.mFormatFlags = kLinearPCMFormatFlagIsBigEndian | kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
		else
			nesAPUState->dataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
		
		nesAPUState->dataFormat.mBytesPerPacket = 2;
		nesAPUState->dataFormat.mFramesPerPacket = 1;
		nesAPUState->dataFormat.mBytesPerFrame = 2;
		nesAPUState->dataFormat.mChannelsPerFrame = 1;
		nesAPUState->dataFormat.mBitsPerChannel = 16;
		nesAPUState->isRunning = NO;
		nesAPUState->bufferFillDelay = 2;
		
		nesAPUState->blipBuffer = blipBuffer;
		
		[self initializeAudioPlaybackQueue];
	}
	
	return self;
}

- (void)dealloc
{
	// Kill the queue and its buffers
	AudioQueueDispose (
					   nesAPUState->queue,
					   true
					   );
	
	// FIXME: Free NES APU Resources
	
	[super dealloc];
}

- (void)pause
{
	nesAPUState->isRunning = NO;
}

- (void)resume
{
	if (!nesAPUState->bufferFillDelay) nesAPUState->isRunning = YES;	
}

- (void)stopAPUPlayback
{
	nesAPUState->isRunning = NO;
	AudioQueueStop (nesAPUState->queue,false);
}

- (void)beginAPUPlayback
{
	nesAPUState->isRunning = NO;
	nesAPUState->bufferFillDelay = 4;
	
	// Prime the playback buffer
	for (int i = 0; i < NUM_BUFFERS; ++i) {
		
		HandleOutputBuffer (
							nesAPUState,
							nesAPUState->queue,
							nesAPUState->buffers[i]
							);
	}
	
	AudioQueueStart (
					 nesAPUState->queue,
					 NULL
					 );
}

/*
- (void)determineBufferSizeGivenMaxPacketSize:(UInt32)maxPacketSize andSeconds:(Float64)seconds
{
    static const int maxBufferSize = 640000;                        // 5 seconds, 16-bit stereo at 32kHz
    static const int minBufferSize = 64000;                         // .5 seconds, 16-bit stereo at 32kHz
	
	Float64 numPacketsForTime = spcPlayerState->dataFormat.mSampleRate / spcPlayerState->dataFormat.mFramesPerPacket * seconds;
	spcPlayerState->bufferByteSize = numPacketsForTime * maxPacketSize;
	
    if (                                                             // Sets buffer size lower if maximum is exceeded
        spcPlayerState->bufferByteSize > maxBufferSize &&
        spcPlayerState->bufferByteSize > maxPacketSize
		)
        spcPlayerState->bufferByteSize = maxBufferSize;
    else {
        if (spcPlayerState->bufferByteSize < minBufferSize)
            spcPlayerState->bufferByteSize = minBufferSize;
    }
	
    spcPlayerState->numPacketsToRead = spcPlayerState->bufferByteSize / maxPacketSize;
}
 */

// Set function for APU to call when it needs to read memory (DMC samples)
// -(void)setDMCReadFunction:(int(*)(void* user_data, cpu_addr_t))dmcFunction;

// Set output sample rate
- (BOOL)setOutputSampleRate:(long)rate {

	// simpleApu.sample_rate(rate);
	
	return YES;
}

// Write to register (0x4000-0x4017, except 0x4014 and 0x4016)
- (void)writeByte:(uint8_t)byte toAPUFromCPUAddress:(uint16_t)address onCycle:(uint_fast32_t)cycle {

	nesAPU->write_register(cycle, address, byte);
}

// Read from status register at 0x4015
- (uint8_t)readAPUStatusOnCycle:(uint_fast32_t)cycle {

	return nesAPU->read_status(cycle);
}

// End a 1/60 sound frame
- (void)endFrameOnCycle:(uint_fast32_t)cycle {

	nesAPU->end_frame(cycle);
	blipBuffer->end_frame(cycle);
	
	if (nesAPUState->bufferFillDelay > 0) nesAPUState->bufferFillDelay--;
	else nesAPUState->isRunning = YES;
}

// Number of samples in buffer
- (long)numberOfBufferedSamples {
	
	return blipBuffer->samples_avail();
}

// Save/load snapshot of emulation state
- (void)saveSnapshot {

}

- (void)loadSnapshot {
	
}

@end