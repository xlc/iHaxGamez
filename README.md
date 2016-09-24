This is my fork of iHexGamez which is adopted from [http://sourceforge.net/projects/ihaxgamez/](http://sourceforge.net/projects/ihaxgamez/)

It was originally designed to have backward capability but I dropped it to make things easier. Therefore my version currently only support 64bits Lion.

----------------------------------

### Changes/Further update

The initial commit is import from the Google doc svn repo but I rewrite most of the code:

- Use ARC to save works from memory management
- Re-write all the memory access code
	- Use privileged helper instead execute main app in root privilege.
- Support Auto-type (working but not perfect yet)
- Re-designed the interface to make it easier to use (At least easier for me)
- Support global hot key to show search window
- Add hex viewer
	- Using [HexFiend framework](https://github.com/ridiculousfish/HexFiend).
- Unknown value search.

----------------------------------

### How to build

ServiceManagement.framework uses code signatures to insure that the helper tool is the one expected to be run by
the main application. Therefore, you will need a code signing identity to build the app.

You can get a self-signed code signing identity using these steps:

- Launch Keychain Access.
- Select Keychain Access > Certificate Assistant > Create a Certificate...
- In the Name field, enter "iHaxGamez".
- Change Certificate Type to "Code Signing".
- Press Continue.
- Back to Xcode and hit build.
