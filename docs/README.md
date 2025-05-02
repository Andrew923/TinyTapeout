# Design Process

Here's an overview of some of the timeline for the important steps in the
design process for this project:

**Shortreals:** The first time I tried synthesizing, I got a syntax error on a line
where I declared a shortreal variable. In my original design I planned on using
shortreals (the equivalent of a C float) to have more precision in my kinematic
parameters. I realized at this point that Yosys did not in fact support shortreals
so I had to basically rethink my logic. I ended up using shortints and interpreting
the lowest 4 bits as if they were decimal points, so at any point my actual particle
positions are at (x >>> 4, y >>> 4). This way I could have a little precision.

**Multipliers:** After my first successful synthesis, I was greeeted with the following
element usage statistics:

```
Info: Device utilisation:
Info:             TRELLIS_IO:    19/  197     9%
Info:                   DCCA:     2/   56     3%
Info:                 DP16KD:     0/   56     0%
Info:             MULT18X18D:   181/   28   646%
Info:                 ALU54B:     0/   14     0%
Info:                EHXPLLL:     1/    2    50%
Info:                EXTREFB:     0/    1     0%
Info:                   DCUA:     0/    1     0%
Info:              PCSCLKDIV:     0/    2     0%
Info:                IOLOGIC:     0/  128     0%
Info:               SIOLOGIC:     0/   69     0%
Info:                    GSR:     0/    1     0%
Info:                  JTAGG:     0/    1     0%
Info:                   OSCG:     0/    1     0%
Info:                  SEDGA:     0/    1     0%
Info:                    DTR:     0/    1     0%
Info:                USRMCLK:     0/    1     0%
Info:                CLKDIVF:     0/    4     0%
Info:              ECLKSYNCB:     0/   10     0%
Info:                DLLDELD:     0/    8     0%
Info:                 DDRDLL:     0/    4     0%
Info:                DQSBUFM:     0/    8     0%
Info:        TRELLIS_ECLKBUF:     0/    8     0%
Info:           ECLKBRIDGECS:     0/    2     0%
Info:                   DCSC:     0/    2     0%
Info:             TRELLIS_FF:  4158/24288    17%
Info:           TRELLIS_COMB: 33586/24288   138%
Info:           TRELLIS_RAMW:     0/ 3036     0%
```
Notably, the multiplier usage was very overbudget. I spent a long time implementing
pipelining and refactoring my code in a way such that Yosys would figure out that
my multiplier was being time division multipliexed. Here's my current element
usage:

```
Info: Device utilisation:
Info:             TRELLIS_IO:    19/  197     9%
Info:                   DCCA:     2/   56     3%
Info:                 DP16KD:     0/   56     0%
Info:             MULT18X18D:     4/   28    14%
Info:                 ALU54B:     0/   14     0%
Info:                EHXPLLL:     1/    2    50%
Info:                EXTREFB:     0/    1     0%
Info:                   DCUA:     0/    1     0%
Info:              PCSCLKDIV:     0/    2     0%
Info:                IOLOGIC:     0/  128     0%
Info:               SIOLOGIC:     0/   69     0%
Info:                    GSR:     0/    1     0%
Info:                  JTAGG:     0/    1     0%
Info:                   OSCG:     0/    1     0%
Info:                  SEDGA:     0/    1     0%
Info:                    DTR:     0/    1     0%
Info:                USRMCLK:     0/    1     0%
Info:                CLKDIVF:     0/    4     0%
Info:              ECLKSYNCB:     0/   10     0%
Info:                DLLDELD:     0/    8     0%
Info:                 DDRDLL:     0/    4     0%
Info:                DQSBUFM:     0/    8     0%
Info:        TRELLIS_ECLKBUF:     0/    8     0%
Info:           ECLKBRIDGECS:     0/    2     0%
Info:                   DCSC:     0/    2     0%
Info:             TRELLIS_FF:  2733/24288    11%
Info:           TRELLIS_COMB: 16797/24288    69%
Info:           TRELLIS_RAMW:     0/ 3036     0%
```
I probably could have gotten down the multiplier usage to just 1,
but since it synthesized I just moved on.

**SPI:** The basic requirements for SPI communication were just to
do a few writes in the beginnning for IMU configuration and then
just read the values I wanted in a loop. Unfortunately, I ran into
a lot of problems. Most of them were related to getting inconsistent values
when reading the fields. Some bits were flickering and others weren't,
but the values didn't make sense at all. The flickering also varied based
on how much delay there was between reading each field. I went into a bit of
a deep dive into the datasheet at this point to make sure I wasn't getting
any setup or hold tim violations. At the end I kind of just rewrote the module
and it somehow just started working.

**Simulation Parameters:** 
Some parts of translating the soft body physics logic were a bit weird.
For example, the concept of a time step delta didn't really make sense
because the update rate in hardware is so high. I ended up replacing it with
some constant bit shift operation. Another part that was difficult to deal
with was the calculation for distance. Since I couldn't really do square
rooting I ended up with just euclidean distance squared which makes the math
a bit weird. I tried looking into approaches like the fast inverse square
root algorithm (relies on floats unfortunately) but there wasn't really any
great approximation for square roots. I did a lot of inspecting the
waveform viewer to look at the actual values and just played around.
