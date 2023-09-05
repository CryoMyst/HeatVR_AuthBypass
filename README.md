# HeatVR_AuthBypass
HWID Authentication for Anthro Heat VR Game.

https://www.patreon.com/heatgame

Now in a more conventient powershell script instead of a .net executable. 

## Steps
1. Download the HeatUnlocker.ps1 script
2. Verify the contents of the script
3. Run the script
4. Enjoy not needing to authentication via Patreon

## Explanation
Instead of patching the binary this makes use of the Auth class behaviour of a HWID in the PlayerPrefs allowing bypassing Patreon. Therefore this will work for all versions until they patch this mode of authentication out.
![Auth Class](AuthClass.png)