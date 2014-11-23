Mousecape
===

A free cursor manager for Mac OS 10.8+ built using private, nonintrusive CoreGraphics APIs.

## How it works

Mousecape works by calling the API calls that Apple uses to initialize the system cursors in the system and it registers a daemon that will automatically apply the cursor on login and when cursors get unregistered.

It is unintrusive and works in the background. You just need to open the app, click **Mousecape --> Install Helper Tool**, apply your cursor and you're done!

## Where do I get cursors?

A pack of cursors in Mousecape is called a cape, each cape contains a multiple scales of representations of many cursors. For example, the Arrow cursor can have 1x, 2x, 5x, and 10x representations while the Wait cursor can have 1x, and 2x. 

There is an example cape file included in this Git Repo located [here for download](https://github.com/alexzielenski/Mousecape/blob/master/Mousecape/com.maxrudberg.svanslosbluehazard.cape). It is a remake of [Max Rudberg's](http://maxrudberg.com/) loved Svanslös cursors generously crafted by Max for us to use. Simply double click the cape file with Mousecape on your system and it will be imported into your library.

## How can I create my own cape?

You can create a new cape document in the Mousecape app by hitting &#8984;N (Command-N) and editing it with &#8984;E. Click the "+" button to add cursors to customize and symply drag your images into the fields provided.

## How do animated cursors work?

When you want to animate a cursor, change the value in the frames field in the edit window and make sure frame duration is how you want it. Next, create an image that has all of your cursor frames stacked on top of each other vertically. Mousecape will traverse down the image for each frame, using a box the same size as whatever you put in the size field.

## How can I say thanks?

Tell your friends.

## Where can I get a copy of this sweet tool?

In the [releases section](https://github.com/alexzielenski/Mousecape/releases) of this GitHub page. There are stable reases there. **The current version is 0.0.5**.

## LICENSE

I worked very hard researching the private methods used in Mousecape and creating this app. Please respect me and my work by not using any of the information provided here for commercial purposes.

Copyright (c) 2013-2014, Alex Zielenski
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
* Any redistribution, use, or modification is done solely for personal benefit and not for any commercial purpose or for monetary gain

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

