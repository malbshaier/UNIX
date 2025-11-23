
                         trainer.sh
             Interactive Unix Permissions Gym - Level Up Your chmod
===============================================================================

This is not a cheat sheet.  
This is a dojo.

A tiny Bash script that builds real files, throws real challenges at you,  
and instantly tells you - in plain English - exactly which permission bit  
you got wrong. No slides. No theory. Just you vs the octal.

-------------------------------------------------------------------------------
HOW IT WORKS (four commands, that’s all)
-------------------------------------------------------------------------------
$ ./trainer.sh new 1          # drops you into Level 1
$ # ← you read the goal and start typing real chmod/chown/umask commands
$ ./trainer.sh check 1        # instant verdict + detailed hint if you fail
$ ./trainer.sh reset 1        # wipe and start the same level again
$ ./trainer.sh clean          # nuke everything when you’re done

That’s literally it.

-------------------------------------------------------------------------------
THE FOUR TRAINING STAGES
-------------------------------------------------------------------------------
[1] Classic file permissions
    Turn a wide-open file into 640 using either octal or symbolic notation

[2] Directories & execute bit
    Make a directory traversable (775) and a script executable by everyone (755)

[3] Symbolic gymnastics
    Achieve 646 using only symbolic flags (g+w,o+r, etc.) - no octal allowed in spirit

[4] umask mastery
    Set umask 027 and create a new file that ends up exactly 640

-------------------------------------------------------------------------------
WHAT YOU GET WHEN YOU FAIL (example)
-------------------------------------------------------------------------------
Fail
Hint: Mode should be 640 (rw-r-----). Current: 644
Bit differences:
  Others bit wrong: Expected ---, got r--

No vague “wrong permissions” messages. You see exactly where you slipped.

-------------------------------------------------------------------------------
WHAT YOU GET WHEN YOU SUCCEED
-------------------------------------------------------------------------------
Pass! Mode is correct.
Score: 12 passes out of 15 attempts

Score is saved between sessions in a hidden .trainer_state file.

-------------------------------------------------------------------------------
SAFETY FIRST
-------------------------------------------------------------------------------
- All work happens inside practice_level1/, practice_level2/, etc.
- Your real home directory and files are never touched
- One command (./trainer.sh clean) deletes everything instantly

-------------------------------------------------------------------------------
COMPATIBILITY
-------------------------------------------------------------------------------
- 100% Linux only (uses GNU stat -c '%a')
- Tested on Ubuntu, Debian, Fedora, Arch, CentOS, WSL2
- macOS is NOT supported (different stat format)
- Zero dependencies beyond standard GNU tools

-------------------------------------------------------------------------------
ONE FILE. NO INSTALL. INSTANT PRACTICE.
-------------------------------------------------------------------------------
Just do:

chmod +x trainer.sh
./trainer.sh new 1

…and start turning permission confusion into muscle memory.

MIT licensed - use it in classes, labs, bootcamps, or just to finally stop  
googling “chmod group read only” at 2 a.m.

Ready to stop guessing and start knowing?

Type  ./trainer.sh new 1  and begin.

You’ve got this.
===============================================================================
