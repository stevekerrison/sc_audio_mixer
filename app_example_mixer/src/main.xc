
#include <xs1.h>
#include <print.h>

#include "mixer.h"

#define MIXER_COUNT 1

#if(MIXER>2)
#error only MIXER_COUNT up to 2 supported
#endif

/* Sinwave tables */
int g_sinewave[8][48] =
	{
		{ // Channel 0
			0, 1094933, 2171131, 3210181, 4194303, 5106660, 5931641, 6655129, 7264747, 7750062, 8102772, 8316841, 8388607, 8316841, 8102772, 7750062, 7264747, 6655129, 5931641, 5106660, 4194304, 3210181, 2171131, 1094933, 0, -1094933, -2171131, -3210181, -4194303, -5106660, -5931641, -6655129, -7264747, -7750062, -8102772, -8316841, -8388607, -8316841, -8102772, -7750062, -7264747, -6655129, -5931641, -5106660, -4194304, -3210181, -2171131, -1094933
		},
		{ // Channel 1
			0, 2171131, 4194303, 5931641, 7264747, 8102772, 8388607, 8102772, 7264747, 5931641, 4194304, 2171131, 0, -2171131, -4194303, -5931641, -7264747, -8102772, -8388607, -8102772, -7264747, -5931641, -4194304, -2171131, 0, 2171131, 4194303, 5931641, 7264747, 8102772, 8388607, 8102772, 7264747, 5931641, 4194304, 2171131, 0, -2171131, -4194303, -5931641, -7264747, -8102772, -8388607, -8102772, -7264747, -5931641, -4194304, -2171131
		},
		{ // Channel 2
			0, 3210181, 5931641, 7750062, 8388607, 7750062, 5931641, 3210181, 0, -3210181, -5931641, -7750062, -8388607, -7750062, -5931641, -3210181, 0, 3210181, 5931641, 7750062, 8388607, 7750062, 5931641, 3210181, 0, -3210181, -5931641, -7750062, -8388607, -7750062, -5931641, -3210181, 0, 3210181, 5931641, 7750062, 8388607, 7750062, 5931641, 3210181, 0, -3210181, -5931641, -7750062, -8388607, -7750062, -5931641, -3210181
		},
		{ // Channel 3
			0, 4194303, 7264747, 8388607, 7264747, 4194304, 0, -4194303, -7264747, -8388607, -7264747, -4194304, 0, 4194303, 7264747, 8388607, 7264747, 4194304, 0, -4194303, -7264747, -8388607, -7264747, -4194304, 0, 4194303, 7264747, 8388607, 7264747, 4194304, 0, -4194303, -7264747, -8388607, -7264747, -4194304, 0, 4194303, 7264747, 8388607, 7264747, 4194304, 0, -4194303, -7264747, -8388607, -7264747, -4194304
		},
		{ // Channel 4
			0, 5106660, 8102772, 7750062, 4194304, -1094933, -5931641, -8316841, -7264747, -3210181, 2171131, 6655129, 8388607, 6655129, 2171131, -3210181, -7264747, -8316841, -5931641, -1094933, 4194303, 7750062, 8102772, 5106660, 0, -5106660, -8102772, -7750062, -4194304, 1094933, 5931641, 8316841, 7264747, 3210181, -2171131, -6655129, -8388607, -6655129, -2171131, 3210181, 7264747, 8316841, 5931641, 1094933, -4194303, -7750062, -8102772, -5106660
		},
		{ // Channel 5
			0, 5931641, 8388607, 5931641, 0, -5931641, -8388607, -5931641, 0, 5931641, 8388607, 5931641, 0, -5931641, -8388607, -5931641, 0, 5931641, 8388607, 5931641, 0, -5931641, -8388607, -5931641, 0, 5931641, 8388607, 5931641, 0, -5931641, -8388607, -5931641, 0, 5931641, 8388607, 5931641, 0, -5931641, -8388607, -5931641, 0, 5931641, 8388607, 5931641, 0, -5931641, -8388607, -5931641
		},
		{ // Channel 6
			0, 6655129, 8102772, 3210181, -4194303, -8316841, -5931641, 1094933, 7264747, 7750062, 2171131, -5106660, -8388607, -5106660, 2171131, 7750062, 7264747, 1094933, -5931641, -8316841, -4194304, 3210181, 8102772, 6655129, 0, -6655129, -8102772, -3210181, 4194303, 8316841, 5931641, -1094933, -7264747, -7750062, -2171131, 5106660, 8388607, 5106660, -2171131, -7750062, -7264747, -1094933, 5931641, 8316841, 4194304, -3210181, -8102772, -6655129
		},
		{ // Channel 7
			0, 7264747, 7264747, 0, -7264747, -7264747, 0, 7264747, 7264747, 0, -7264747, -7264747, 0, 7264747, 7264747, 0, -7264747, -7264747, 0, 7264747, 7264747, 0, -7264747, -7264747, 0, 7264747, 7264747, 0, -7264747, -7264747, 0, 7264747, 7264747, 0, -7264747, -7264747, 0, 7264747, 7264747, 0, -7264747, -7264747, 0, 7264747, 7264747, 0, -7264747, -7264747
		}
	};

void DoSamples(streaming chanend c_in, streaming chanend c_out)
{
    unsigned buffer[MIXER_NUM_CHAN_IN];

    for(int i = 0; i < 48; i++)
    {
        /* Send out our sine waves */
        for(int j = 0; j < MIXER_NUM_CHAN_IN; j++)
        {
            if(j < 8)
            {
                c_in <: g_sinewave[j][i]<<8; 
            }
            else
            {
                c_in <: 0;              
            }
        } 
 
        /* Receive mixes back.. */
        for(int i = 0; i < MIXER_NUM_CHAN_OUT; i++)
        {
            c_out :> buffer[i];
        }

        /* Print input samples */
        for(int j = 0; j < MIXER_NUM_CHAN_IN; j++)
        {
            if(j < 8)
            {
                //printint(g_sinewave[j][i]<<8);  
            }
            else
            {
                //printint(0);
            }
            //printstr(" ");             
        } 

        /* Print received samples*/
        for(int i = 0; i < MIXER_NUM_CHAN_OUT; i++)
        {
            //printint(buffer[i]);
            //printstr(" ");
        }
        //printstrln("");        
    }

}

void MixerTest(streaming chanend c_in, streaming chanend c_out, chanend c_ctrl)
{
    //printstr("#Original Channels\n");    
    DoSamples(c_in, c_out);   

    /* Update some volumes */
    //printstr("#Nobble weights\n"); 
    Mixer_UpdateWeight(c_ctrl, 0, 0, 0x900000);  
    Mixer_UpdateWeight(c_ctrl, 1, 1, 0x900000);  
    DoSamples(c_in, c_out); 

    //printstr("#Mix 0: Mix in channel 1\n");
    Mixer_UpdateWeight(c_ctrl, 0, 1, 0x900000);  
    DoSamples(c_in, c_out); 

    //printstr("#Mix 1: Mix channel 1 and 2\n");
    Mixer_UpdateWeight(c_ctrl, 1, 1, 0xa00000);  
    Mixer_UpdateWeight(c_ctrl, 1, 2, 0x900000);  
    DoSamples(c_in, c_out); 

    //printstr("#Mix1: Saturation test\n");
    Mixer_UpdateWeight(c_ctrl, 0, 1, 0x2000000);  
    Mixer_UpdateWeight(c_ctrl, 0, 2, 0x200000);  
    DoSamples(c_in, c_out); 

    /* Kill off mixer thread */
    Mixer_Kill(c_ctrl);
    soutct(c_in,XS1_CT_PAUSE);
    soutct(c_out,XS1_CT_PAUSE);
}

void dummy()
{

}

int main(void)
{
    streaming chan c_in[MIXER_COUNT], c_out[MIXER_COUNT];
    chan c_ctrl[MIXER_COUNT];

    par
    {
        /* Call mixer thread */
        Mixer(c_in[0], c_out[0], c_ctrl[0]);

        /* Call thread to test mixer */
        MixerTest(c_in[0], c_out[0], c_ctrl[0]);
        
        /* Some dummy threads - so we get worst case XTA timing */
        dummy();
        dummy();
        dummy();
        dummy();
        dummy();
        dummy();
    }

    return 0;
}
