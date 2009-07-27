Twitter+OAuth Source and Example for iPhone
Glommed together by Ben Gottlieb
©2009 Stand Alone, Inc - all rights reserved.
License: BSD, If you use it, please include the following text somewhere in your application's user-facing text:
"Includes Twitter+OAuth code by Ben Gottlieb"

The goal of this was to create a drop-in code package for iPhone apps that want to access Twitter via OAuth. The main benefit here is that the source line on the Twitter page will say your app name, rather than "from web". 

This includes source taken from several other open frameworks, listed below. Most of the heavy lifting was all done by them, I just synthesized it into a (hopefully) easily digestible chunk.

I decided not to do the whole thing as a static library since most developers are already using Matt Gemmell's MGTwitterEngine, and there was no reason to duplicate code. It adds about 200k to the final size of your project, mainly due to the OAuth library.

Enjoy, and please let me know if you have any feedback!

Ben Gottlieb
ben@standalone.com




Example:
I've included a compiled example with my own OAuth keys.
I did this so that you have an example of how the app should behave after you insert your own keys obtained from twitter.  You can find the example in:
OAuth_ObjC_Test_App/Example/



To Use:
You will need to create an OAuth applicaton registration on the Twitter site:
 http://twitter.com/oauth_clients/new
Use the key and secret info provided there to modify the constants at the top of YHOAuthTwitterEngine.m
You should also set up your callback url at the top of the YHTwitter.m



Built using:
MGTwitterEngine by Matt Gemmell
http://mattgemmell.com
License:  http://mattgemmell.com/license
I have included 1.0.8 release of the MGTwitterEngine unchanged in this project.  
The goal is to create an easily buildable project that has no dependancies.


OAuthConsumer Framework
Jon Crosby
http://code.google.com/p/oauth/
License:  http://www.apache.org/licenses/LICENSE-2.0
I have included a pre-built binary of the OAuthConsumer Framework unchanged in this project.  
The goal is to create an easily buildable project that has no dependancies.


OAuth-MyTwitter
Chris Kimpton
http://github.com/kimptoc/MGTwitterEngine-1.0.8-OAuth-MyTwitter/tree/master
License:  Couldn't find one.  Will amend this if I do.
Some code from this project was used to create the YHOATwitterEngine subclass of MGTwitterEngine.
Thanks Chris, you made this project a simple!


OAuth Test Application
Isaiah Carew
http://github.com/yourhead/OAuth_ObjC_Test_App/tree/master
License: None found.
Isaiah's test app worked great on the Mac, but didn't make use of the PIN number passed back by Twitter, and also needed to be re-worked to work on the phone.
