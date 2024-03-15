# Running ChatGPT on the Altair 8800

This directory contains code and instructions on running ChatGPT on the Altair 8800. More details can be found on [YouTube](https://www.youtube.com/watch?v=d6jKWQAkzLc).

## Requirements

These instructions assume that you have the following devices available:
* Altair 8800 capable of running simple programs
* The [88-2SIOJP](https://deramp.com/2SIOJP.html) serial board.
* A serial-to-ethernet adapter (I used [USR-TCP232-306](https://amzn.to/3IB4uJh) but you can also use the less expensive [USR-TCP232-302](https://amzn.to/4adqvcR))
* A straight-through serial cable (DB9 to DB25 or a variant of those). Make sure it's not a NULL modem cable as those are cross-over.
* A machine cable of running [socat](https://www.redhat.com/sysadmin/getting-started-socat). I used a [Raspberry PI 4](https://amzn.to/48SAHGx)
* An OpenAI API key. If you go to the [documentation](https://platform.openai.com/docs/overview), you can create a free account from there. You might still be able to get free credits to try it out.

## Instructions

1. Create an OpenAI API key outlined in the [OpenAI documentation](https://platform.openai.com/docs/overview). Click on "API Keys" on the left menu.

2. Copy the `chatgpt.sh` file to a Raspberry PI (or another compatible device) and make sure that it's executable by socat. You can set its permissions to 700 (`chmod 700 chatgpt.sh`), for example, but be careful with permissions.

3. Install dependencies:

```
sudo apt-get install libcurl jq wc awk
```

4. Run socat:

```
socat -x -ddd tcp-listen:8000,reuseaddr,fork EXEC:"bash /path/to/chatgpt.sh"
```

5. Connect the serial-to-ethernet device to the 88-2SIOJP serial port 2. Serial port 1 will be connected to a terminal or external computer for input and output.

6. Configure the serial-to-ethernet device using the [software](https://www.pusr.com/support/downloads) provided by PUSR. As of this writing, it's called "USR-M0 V2.2.6.1.exe". Set it to "TCP Client" and set the host IP to the Raspberry PI IP address and port to 8000. Save the settings. At this point, the serial-to-ethernet device should be connected to socat - you will see activity on the socat screen.

7. Copy `CHATGPT.ASM` to the Altair. You can either use AMON and copy the HEX file to address 0 or use the method outlined in [this YouTube video](https://www.youtube.com/watch?v=lt8m1Byoukw) on copying it to an IDE drive and booting from that.

8. Run the program. You will see the following when the program starts:

```
ChatGPT Assistant. Ask away!
>
```