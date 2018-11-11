Moonsound/Wozblaster Onboard RAM Tester
ZX Version Copyright (C) 2015 Micklab
MSX Version Copyright (C) 2015 Alexey Podrezov
MSX Version Copyright (C) 2018 Volodymyr Bezobiuk


DISCLAIMER
----------
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS” AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
OF THE POSSIBILITY OF SUCH DAMAGE.


ABOUT
-----
The MOONTEST utility is based on the ZX Spectrum version of the MOOMSERVICE utility
that was created by Micklab.

This utility tests one or both RAM chips of the MSX based Moonsound or Wozblaster
sound cards. The test is done 3 times in a row. To stop the test at any time please
press any button.

The test indication is shown per "bank". Each bank corresponds to a single 512kb
RAM chip on board of the sound card. Each "bank" is tested in 16kb chunks, so in total
32 chunks are tested for each RAM chip. The utility outputs a series of symbols during
testing. A dot "." means that the corresponding 16kb chunk is good, the "x" means that
the corresponding 16kb chunk has at least one read/write error.


USAGE
-----
Run the MOONTEST.COM file under MSX-DOS. Wait for the test to complete or press any key
to stop the test. Enjoy.


DISTRIBUTION
------------
The utility is provided for free without any warranty. Free distribution is allowed
as long as the utility's binary file is not modified and if it is accompanied by this
ReadMe file. The source code is available on request.

If you would like to contact the author (Alexey Podrezov) or to make a small donation
in appreciation for the author's efforts, please use this e-mail address:

alexey.podrezov@gmail.com

MSX FOREVER!
