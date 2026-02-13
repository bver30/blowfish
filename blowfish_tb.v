`timescale 1ns/1ps

module blowfish_tb;

    reg clk;
    reg start;
    reg rst;
	 reg enc;
	 reg dec;
    reg [63:0] plaintext;
    reg [63:0] key;

    wire [63:0] encryptedtext;
    wire [63:0] decryptedtext;
    wire DECRYPT_DONE;
    wire ENCRYPT_DONE;
   

    // DUT instantiation (ONLY ONE INSTANCE)
    blowfish uut (
        .clk(clk),
        .rst(rst),
		  .enc(enc),
		  .dec(dec),
        .start(start),
        .key(key),
        .plaintext(plaintext),
        .encryptedtext(encryptedtext),
        .decryptedtext(decryptedtext),
        .DECRYPT_DONE(DECRYPT_DONE),
        .ENCRYPT_DONE(ENCRYPT_DONE)
       
    );

    // Clock generation
    always #10 clk = ~clk;

    // Waveform dump (with internal state visibility)
    initial begin
        $dumpfile("blowfish.vcd");
        $dumpvars(0, blowfish_tb);

    end

    // Stimulus
    initial begin
        clk       = 0;
        rst       = 1;
        start     = 0;
		  enc			= 1;
		  dec 		= 0;
        plaintext = 64'h0;
        key       = 64'h0;

         #300 rst = 0;

        plaintext = 64'h0123456789abcdef;
        key       = 64'hcade514815fde3a8;

        start = 1; #1000;
		  enc   = 0;
		  dec   = 1;
        
		  
		 

        #2000 $finish;
    end

    // Monitor
    initial begin
        $monitor(
            "Time=%0t clk=%h rst=%h start=%h ENC_DONE=%h DEC_DONE=%h plaintext=%h ciphertext=%h decryptedtext=%h",
            $time, clk, rst, start,
             // <-- FSM state visible in console
             ENCRYPT_DONE, DECRYPT_DONE,
            plaintext, encryptedtext, decryptedtext
        );
    end

endmodule
