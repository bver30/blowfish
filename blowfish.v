	module blowfish (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [63:0] key,            // FLOATING!!!
    input  wire [63:0] plaintext,

    output reg  [63:0] encryptedtext,
    output reg  [63:0] decryptedtext,
    output reg         DECRYPT_DONE,
    output reg         ENCRYPT_DONE,

    input  wire        enc,
    input  wire        dec
);

    reg [31:0] temp, left, right;
    reg [31:0] p_array [0:17];
    reg [31:0] s_box0  [0:255];
    reg [31:0] s_box1  [0:255];
    reg [31:0] s_box2  [0:255];
    reg [31:0] s_box3  [0:255];
    reg [4:0]  round;
    reg [4:0]  state;
    reg [63:0] ciphertext;
    reg        init;

    // local param
    localparam IDLE           = 4'd0,
               INIT           = 4'd1,
               ENCRYPT_LEFT   = 4'd2,
               ENCRYPT_FINAL  = 4'd3,
               ENCRYPT_UNDO   = 4'd4,
               DECRYPT_LEFT   = 4'd5,
               DECRYPT_FINAL  = 4'd6,
               DONE           = 4'd7,
               ENCRYPT_RIGHT  = 4'd8,
               DECRYPT_RIGHT  = 4'd9,
               TRANSITION     = 4'd10;

    // F function
    function [31:0] F;
        input [31:0] x;
        begin
           /* F = ((s_box0[x[31:24]] + s_box1[x[23:16]])
                 ^  s_box2[x[15:8]]) + s_box3[x[7:0]]; */
					  
					 
				F = ((s_box0[x[31:24]] + s_box1[x[23:16]]) ^ 
					 s_box2[x[15:8]]) + x[7:0];
					 
					/* F = ((s_box0[x[31:24]]) ^ x[23:16])
                 +  ((s_box1[x[15:8]]) ^ x[7:0]);
					*/
        end
    endfunction

    // FSM logic
    always @(posedge clk) begin
        if (rst) begin

            $readmemh("p_array.hex", p_array);
            $readmemh("sbox0.hex",   s_box0);
            $readmemh("sbox1.hex",   s_box1);
            $readmemh("sbox2.hex",   s_box2);
            $readmemh("sbox3.hex",   s_box3);

            round          <= 0;
            left           <= 0;
            right          <= 0;
            temp           <= 0;
            encryptedtext  <= 64'h0;
            decryptedtext  <= 64'h0;
            ENCRYPT_DONE   <= 0;
            DECRYPT_DONE   <= 0;
            init           <= 0;
            state          <= IDLE;

        end else begin
            case (state)

                IDLE: begin
                    if (!start)
                        state <= INIT;
                    else
                        state <= TRANSITION;
                end

                TRANSITION: begin
                    if (start && enc && !ENCRYPT_DONE) begin
                        left  <= plaintext[63:32];
                        right <= plaintext[31:0];
                        round <= 0;
                        state <= ENCRYPT_RIGHT;

                    end else if (ENCRYPT_DONE && !DECRYPT_DONE && dec) begin
                        state <= ENCRYPT_UNDO;

                    end else begin
                        state <= IDLE;
                    end
                end

                INIT: begin
                    init  <= 1;
                    state <= IDLE;
                end

                ENCRYPT_RIGHT: begin
                    temp  <= right;
                    right <= left ^ p_array[round];
                    state <= ENCRYPT_LEFT;
                end

                ENCRYPT_LEFT: begin
                    left  <= temp ^ F(right);
                    round <= round + 1;

                    if (round == 13)
                        state <= ENCRYPT_FINAL;
                    else
                        state <= ENCRYPT_RIGHT;
                end

                ENCRYPT_FINAL: begin
                    encryptedtext <= { right ^ p_array[16], left ^ p_array[17] };
                    ciphertext    <= { right ^ p_array[16], left ^ p_array[17] };
                    ENCRYPT_DONE  <= 1;
                    DECRYPT_DONE  <= 0;
                    round         <= 13;
                    right         <= 0;
                    left          <= 0;
                    state         <= TRANSITION;
                end

                ENCRYPT_UNDO: begin
                    left  <= ciphertext[63:32] ^ p_array[16];
                    right <= ciphertext[31:0]  ^ p_array[17];
                    state <= DECRYPT_RIGHT;
                end

                DECRYPT_RIGHT: begin
                    temp  <= right;
                    right <= left ^ p_array[round];
                    state <= DECRYPT_LEFT;
                end

                DECRYPT_LEFT: begin
                    left  <= temp ^ F(left);
                    round <= round - 1;

                    if (round == 0)
                        state <= DONE;
                    else
                        state <= DECRYPT_RIGHT;
                end

                DONE: begin
                    decryptedtext <= { right, left };
                    DECRYPT_DONE  <= 1;
                    state         <= IDLE;
                end

                default: state <= IDLE;
	
            endcase
        end
    end

endmodule
