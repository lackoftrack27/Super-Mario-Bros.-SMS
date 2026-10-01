# Super Mario Bros. Sega Master System Port

A near-perfect port of the NES/FC classic to the Sega Master System. It also introduces new graphics and sound modes that take advantage of the SMS's hardware.

**Download Link:** [https://www.smspower.org/Homebrew/SuperMarioBrosSmsPort-SMS](https://www.smspower.org/Homebrew/SuperMarioBrosSmsPort-SMS)

---
## Features
- **Near-perfect Accuracy:** The game plays almost exactly like the original. While I cannot guarantee _perfect_ accuracy, I feel confident that the port is accurate under _normal gameplay_. 
- **New Graphics Mode:** The port introduces a new graphics mode based on the SNES/SFC port of the game in *Super Mario All-Stars/Super Mario Collection*. Savor the pseudo 16-bit graphics with more color, backgrounds, and style!
- **New Sound Mode:** The port also introduces a new sound mode that takes advantages of the YM2413 FM synthesizer found in the Japanese Sega Master System and commonly added to systems through aftermarket modifications. This new sound mode's music is based on the music in *Super Mario All-Stars/Super Mario Collection*. Immerse yourself in the rich, 16-bit style arrangements! 
	- _Requires a console with a YM2413._
	- _The Sega Mark III's FM Sound Unit is not compatible with this mode._

---

## Credits
- **Nintendo** - For creating a legendary game.
- **doppelganger** - 6502 [disassembly](https://gist.github.com/1wErt3r/4048722) of the original game. Used as reference.
- **MrWint** - 6502 [disassembly](https://github.com/MrWint/smb-dis/blob/master/smbdispal.asm) of the PAL version of the game. Used as reference.
- **TakuikaNinja** - reworked [disassembly](https://github.com/TakuikaNinja/smb1-bugfix) with many QoL improvements. Used as reference.
- **LadiesMan217** - [AMK ports](https://www.smwcentral.net/?p=viewthread&t=102776) of SMAS/SMC music. Used in FM music creation.
- **Jabberwocky** - Provided code for their own mid-progress port of the game.
- **scracchin** - General graphics help.
- **rstbones** - Score point and Bowser graphics for the new graphics mode.
- **All Testers!** - fx, New Horizon, elfor, AtariBorn, chirinea, Darakutenshi, EmuBoarding, Melanogaster

Additional Credits:
- **Einar Saukas** - [ZX7 compression](https://spectrumcomputing.co.uk/entry/27996/ZX-Spectrum/ZX7) Algorithm used here to compress graphics and tilemaps
- **Maxim** - [BMP2Tile](https://github.com/maxim-zhao/bmp2tile)
---

## Changelog
**v1.10**
- Reduce slowdown
- Fix reset button not working on Mega Drive/Genesis systems
- Level 6-3 now has a snow palette in the new graphics mode
- Castle music now plays in the underwater section of level 8-4 in FM mode
- Player can now choose between normal and second quest after beating the game by pressing Left at the title screen
- Player can now have up to 255 lives
- More accurate noise SFXs are now used in FM mode
- Fix issue for some MegaSD users where FM audio wouldn't be audible
- Add extra height builds for users who have a console with a 315-5246 or 315-5681 VDP
- Mario and Luigi now have unique star flags in the new graphics mode
- Animated background elements in the new graphics mode can no longer sometimes freeze
- Fire Mario/Luigi's overalls is now a bit whiter in the NES graphics mode
- Fire Flower and Star power-ups now palette cycle in the new graphics mode
- Allow user to control FM volume by pressing Down at FM sound test

**v1.00**
- Initial release
