// Efe Görkem Akkanat
// 231101046

module akkanat (
    input  wire clk_i,             
    input  wire rst_i,              
    input  wire [31:0]  inst_i,           
    input  wire [31:0]  data_mem_rdata_i,  

    output reg  [31:0]  pc_o,            
    output reg  [31:0]  data_mem_addr_o,    
    output reg  [31:0]  data_mem_wdata_o,   
    output reg data_mem_we_o,     
    output wire [1023:0] regs_o,          
    output reg  [1:0]  cur_stage_o        
);

    reg [2:0] state_q, state_next;
    reg [31:0] pc_next;

    // Pipeline regs
    reg [31:0] alu_out;  // ALU sonucunututar
    reg [31:0] mem_wdata_reg;  // memory ye yazilacak veriyi tutar
    reg [31:0] temp_val_a;     // Karsilastirma gecici register A
    reg [31:0] temp_val_b;     

    // Custom Inst sayaclari/degiskenleri
    reg [31:0] cycle_cnt;      
    reg  found;         
    integer idx;           
    reg [1:0]  step;         

    reg [31:0] registers [0:31];
    integer i;
    genvar k;

    // FSM States
    localparam S_FETCH = 3'b000;
    localparam S_DECODE= 3'b001;
    localparam S_EXECUTE = 3'b010;
    localparam S_WRITE = 3'b011;

    // Opcodes custom+r5
    localparam OPC_LUI= 7'b0110111;
    localparam OPC_AUIPC = 7'b0010111;
    localparam OPC_JAL  = 7'b1101111;
    localparam OPC_JALR  = 7'b1100111;
    localparam OPC_BRANCH    = 7'b1100011;
    localparam OPC_LOAD = 7'b0000011;
    localparam OPC_STORE  = 7'b0100011;
    localparam OPC_OP_IMM    = 7'b0010011; // ADDI, SLTI 
    localparam OPC_OP = 7'b0110011; // ADD, SUB 
    localparam OPC_CUSTOM_1  = 7'b1110111; // SUB.ABS, MOVU, SRT.CMP.ST
    localparam OPC_CUSTOM_2  = 7'b1111111; // MAC.LD.ST, SEL.CND

   
    //decoding
    wire [6:0] opcode = inst_i[6:0];
    wire [4:0] rd  = inst_i[11:7];
    wire [2:0] funct3 = inst_i[14:12];
    wire [4:0] rs1 = inst_i[19:15];
    wire [4:0] rs2 = inst_i[24:20];
    wire [6:0] funct7 = inst_i[31:25];
    // cust int selector
    wire [1:0] select_s2 = inst_i[26:25];

    // Immediate Generate
    wire [31:0] imm_I={{20{inst_i[31]}}, inst_i[31:20]};
    wire [31:0] imm_S={{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
    wire [31:0] imm_B={{19{inst_i[31]}}, inst_i[31], inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
    wire [31:0] imm_U = {inst_i[31:12], 12'b0};
    wire [31:0] imm_J = {{11{inst_i[31]}}, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};

    // Reg read
    wire [31:0] rdata1 = (rs1 == 0)?0:registers[rs1];
    wire [31:0] rdata2 = (rs2 == 0)?0:registers[rs2];


    generate
        for (k = 0; k < 32; k = k + 1) begin : reg_dump
            assign regs_o[k*32 +: 32] = registers[k];
        end
    endgenerate

    //EXECUTion

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            pc_next  <= 0;
            pc_o   <= 0;
            state_q  <= S_FETCH;
            cur_stage_o   <= S_FETCH[1:0];
            alu_out  <= 0;
            mem_wdata_reg  <= 0;
            cycle_cnt  <= 0;
            temp_val_a  <= 0;
            temp_val_b <= 0;
            step  <= 0;
            found  <= 0;
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 0;
            end

        end else begin
            state_q      <= state_next;
            cur_stage_o  <= state_next[1:0];

            //decoda hazirlik
            if (state_q == S_DECODE) begin
                cycle_cnt <= 0;
            end

            //ALU 
            if (state_q == S_EXECUTE) begin
                cycle_cnt <= cycle_cnt + 1;

                case (opcode)
                    OPC_LUI:   alu_out <= imm_U;
                    OPC_AUIPC: alu_out <= pc_o+imm_U;
                    
                    OPC_JAL: begin
                        alu_out <= pc_o + 4;
                        pc_next <= pc_o + imm_J;
                    end
                    OPC_JALR: begin
                        alu_out <= pc_o + 4;
                        pc_next <= rdata1 + imm_I;
                    end
                    OPC_BRANCH: begin
                        case (funct3)
                            3'b000: if (rdata1 == rdata2) pc_next<=pc_o+imm_B; // BEQ
                            3'b101: if ($signed(rdata1) >= $signed(rdata2)) pc_next <= pc_o + imm_B; // BGE
                        endcase
                    end
                    OPC_LOAD:  alu_out <= rdata1 + imm_I;
                    OPC_STORE: begin
                        alu_out       <= rdata1 + imm_S;
                        mem_wdata_reg <= rdata2;
                    end

                    OPC_OP_IMM: begin
                        case (funct3)
                            3'b000: alu_out <= rdata1 + imm_I;     // ADDI
                            3'b001: alu_out <= rdata1 << imm_I[4:0];         // SLLI
                            3'b010: alu_out <= ($signed(rdata1) < $signed(imm_I)) ? 1 : 0;   // SLTI
                            3'b011: alu_out <= (rdata1 < imm_I) ? 1 : 0;       // SLTIU
                            3'b100: alu_out <= rdata1 ^ imm_I;   // XORI
                            3'b110: alu_out <= rdata1 | imm_I;    // ORI
                            3'b111: alu_out <= rdata1 & imm_I;  // ANDI
                        endcase
                    end

                    OPC_OP: begin
                        case (funct3)
                            3'b000: if (funct7[5]) alu_out <= rdata1 - rdata2;    // SUB
                                    else  alu_out <= rdata1 + rdata2;     // ADD
                            3'b001: alu_out <= rdata1 << rdata2[4:0];   // SLL
                            3'b010: alu_out <= ($signed(rdata1) < $signed(rdata2)) ? 1 : 0;  // SLT
                            3'b011: alu_out <= (rdata1 < rdata2) ? 1 : 0;    // SLTU
                            3'b100: alu_out <= rdata1 ^ rdata2;         // XOR
                            3'b101: if (funct7[5]) alu_out <= $signed(rdata1) >>> rdata2[4:0]; // SRA
                                    else  
                                        alu_out <= rdata1 >> rdata2[4:0];   // SRL
                            3'b110: alu_out <= rdata1 | rdata2;  // OR
                            3'b111: alu_out <= rdata1 & rdata2;     // AND
                        endcase
                    end
                    //custom inst tipleri:
                    OPC_CUSTOM_1: begin
                        case (funct3)
                            // SUB.ABS
                            3'b000: alu_out <= (rdata1 > rdata2) ? (rdata1 - rdata2) : (rdata2 - rdata1); 

                            // SEL.PART
                            3'b010: begin 
                                if (inst_i[20] == 1'b1) alu_out <= {16'b0, rdata1[31:16]};
                                else                    alu_out <= {16'b0, rdata1[15:0]};
                            end
                            // AVG.FLR
                            3'b100: alu_out <= ($signed(rdata1) + $signed(imm_I)) >>> 1; 

                            // MOVU 
                            3'b101: alu_out <= {20'b0, inst_i[31:20]}; 

                            // SRCH.BIT.PTRN
                            3'b111: begin
                                found = 0;
                                for (idx = 0; idx <= 24; idx = idx + 1) begin
                                    if (rdata1[idx +: 8] == rdata2[7:0]) found = 1;
                                end
                                alu_out <= found;
                            end

                            // SRT.CMP.ST (2 cycl)
                            3'b001: begin 
                                if (cycle_cnt == 0) begin
                                    // Cycle 0
                                    alu_out  <= ($signed(rdata1) < $signed(rdata2)) ? rdata1 : rdata2; // Kucuk olan (rd adresine gidecek)
                                    temp_val_a  <= ($signed(rdata1) < $signed(rdata2)) ? rdata2 : rdata1; // Buyuk olan (temp)
                                end else begin
                                    // Cycle 1
                                    alu_out  <= registers[rd] + 4;
                                    mem_wdata_reg <= temp_val_a; 
                                end
                            end

                            // LD.CMP.MAX (3 Cycle)
                            3'b110: begin 
                                if (cycle_cnt == 0) temp_val_a <= data_mem_rdata_i; // rd oku
                                if (cycle_cnt == 1) temp_val_b<=data_mem_rdata_i; // rs1 oku
                                if (cycle_cnt == 2) begin
                                    //karsilastir
                                    if (temp_val_a >= temp_val_b && temp_val_a>=data_mem_rdata_i)
                                        alu_out <= temp_val_a;
                                    else if (temp_val_b >= temp_val_a && temp_val_b>=data_mem_rdata_i)
                                        alu_out <= temp_val_b;
                                    else
                                        alu_out<=data_mem_rdata_i;
                                end
                            end
                        endcase
                    end

                    //2. tip cust. ins.
                    OPC_CUSTOM_2: begin
                        case (funct3)
                            // SEL.CND
                            3'b000: begin 
                                case (select_s2)
                                    2'b00: if ($signed(rdata1) == $signed(rdata2)) pc_next <= pc_o + imm_B;
                                    2'b01: if ($signed(rdata1) >= $signed(rdata2)) pc_next <= pc_o + imm_B;
                                    2'b10: if ($signed(rdata1) <  $signed(rdata2)) pc_next <= pc_o + imm_B;
                                    2'b11: pc_next <= pc_o + 4; // NOP behavior
                                endcase
                            end
                            // MAC.LD.ST 
                            3'b111: begin
                                step = cycle_cnt[1:0]; // Mod 4 say
                                if (step == 1) temp_val_a <= data_mem_rdata_i; 
                                if (step == 2) temp_val_b <= temp_val_a * data_mem_rdata_i; 
                            end
                        endcase
                    end
                endcase
            end
            //WB asamasi
            if (state_q ==S_WRITE) begin
                // pc Guncelle
                if (opcode == OPC_JAL || opcode == OPC_JALR || opcode == OPC_BRANCH || (opcode == OPC_CUSTOM_2 && funct3 == 3'b000)) begin
                    pc_o <= pc_next;
                end else begin
                    pc_o <= pc_o + 4;
                end

                if (opcode != OPC_STORE && opcode != OPC_BRANCH && opcode != OPC_CUSTOM_2) begin
                    if (opcode == OPC_LOAD) registers[rd] <= data_mem_rdata_i;
                    else if (rd != 0)   registers[rd] <= alu_out;
                end
            end
        end
    end
    //next stage+ memory

    always @(*) begin
        state_next = state_q;
        data_mem_we_o = 0;
        data_mem_addr_o  = 0;
        data_mem_wdata_o = 0;

        case (state_q)
            S_FETCH:  state_next = S_DECODE;
            S_DECODE: state_next = S_EXECUTE;

            S_EXECUTE: begin
                state_next = S_WRITE; 

                // standart ops
                if (opcode == OPC_STORE) begin
                    data_mem_we_o= 1;
                    data_mem_addr_o = alu_out;
                    data_mem_wdata_o = mem_wdata_reg;
                end else if (opcode == OPC_LOAD) begin
                    data_mem_addr_o = alu_out;
                end

                // custom ops
                if (opcode == OPC_CUSTOM_1) begin
                    // SRT.CMP.ST 
                    if (funct3 ==3'b001) begin 
                        if (cycle_cnt == 0) begin
                            state_next= S_EXECUTE;
                            data_mem_we_o = 1;
                            data_mem_addr_o= registers[rd]; 
                            data_mem_wdata_o = alu_out;
                        end else begin
                            data_mem_we_o = 1;
                            data_mem_addr_o  = registers[rd] + 4; 
                            data_mem_wdata_o = mem_wdata_reg;
                        end
                    end
                    // LD.CMP.MAX 
                    else if (funct3 == 3'b110) begin 
                        if (cycle_cnt == 0) begin state_next = S_EXECUTE; data_mem_addr_o = registers[rd]; end
                        if (cycle_cnt == 1) begin state_next = S_EXECUTE; data_mem_addr_o = registers[rs1]; end
                        if (cycle_cnt == 2) begin state_next = S_WRITE; data_mem_addr_o = registers[rs2]; end
                    end
                end

                if (opcode == OPC_CUSTOM_2 && funct3 == 3'b111) begin// MAC.LD.ST
                    if (cycle_cnt < ((select_s2 + 1) * 4) - 1) begin
                        state_next = S_EXECUTE;
                    end

                    // alt 2ye göre işlemi sec
                    // (her 4 adimda bir 4 artar)
                    if (cycle_cnt[1:0] == 0) data_mem_addr_o = registers[rs1] + (cycle_cnt[31:2] << 2);
                    else if (cycle_cnt[1:0] == 1) data_mem_addr_o = registers[rs2] + (cycle_cnt[31:2] << 2);
                    else if (cycle_cnt[1:0] == 2) data_mem_addr_o = imm_S; 
                    else if (cycle_cnt[1:0] == 3) begin
                        data_mem_addr_o  = imm_S;
                        data_mem_we_o    = 1;
                        data_mem_wdata_o = data_mem_rdata_i + temp_val_b; 
                    end
                end
            end

            S_WRITE: begin
                state_next = S_FETCH;
                if (opcode==OPC_LOAD || opcode==OPC_STORE) begin
                     data_mem_addr_o = alu_out;
                     if (opcode==OPC_STORE) begin
                         data_mem_we_o =1;
                         data_mem_wdata_o = mem_wdata_reg;
                     end
                end
            end
        endcase
    end

endmodule
