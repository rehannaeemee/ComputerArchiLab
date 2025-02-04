class baz;
    rand bit [31:0] in_add;
    rand bit [31:0] temp;
	rand bit [31:0] op1;
	rand bit [31:0] op2;
    rand bit [ 3:0] aluop;
    rand bit [31:0] i1;
	rand bit [31:0] i2;
    rand bit        m2r;
    rand bit [ 4:0] readr1; 
    rand bit [ 4:0] readr2;
    rand bit [ 4:0] writer;
    rand bit [31:0] writed;
    rand bit        regw;
    rand bit [31:0] op11;
	rand bit [31:0] op22;
    rand bit [31:0] op111;

    constraint readr1_constraint { readr1 inside {[4'd0:4'd15]}; }
    constraint readr2_constraint { readr2 inside {[4'd0:4'd15]}; }
    constraint writer_constraint { writer inside {[4'd0:4'd15]}; }
	constraint aluop_constraint {
        aluop inside {4'b0000, 4'b0001, 4'b0010, 4'b0110};
    }
endclass

module testbench
    //***PARAMETERS****//
    //PC
	var logic [31:0] out_address;
	var logic [31:0] in_address;
 	var logic 		 clk;
    //Instruction Memory
	var logic [31:0] Instruction;
	var logic [31:0] Instruction_address;
    var logic [31:0] temp [9:0];
    //ALU
    var logic        zero;
    var logic [31:0] ALUresult;
    var logic [31:0] operand1;
    var logic [31:0] operand2;
    var logic [ 3:0] ALUoperation;
    //Mux
    var logic [31:0] out;
    var logic [31:0] in1;
    var logic [31:0] in2;
    var logic        MemtoReg;
    //Registers
	var logic [31:0] Read_data1;
 	var logic [31:0] Read_data2;
	var logic [ 4:0] Read_reg1;
	var logic [ 4:0] Read_reg2;
	var logic [ 4:0] Write_reg;
	var logic [31:0] Write_data;
	var logic 		 RegWrite;
    //Adder
    var logic [31:0] Sum;
    var logic [31:0] operand11;
    var logic [31:0] operand22;
    //Adder2
    var logic[31:0] operand111;
    var logic [31:0] Sum1;

    //****DECLARATIONS****//        
    PC                DUT1 (.*);
    InstructionMemory DUT2 (.*);
	ALU               DUT3 (.*);
	Mux               DUT4 (.*);
	Registers         DUT5 (.*);
	Add               DUT6 (.*);
	Add2              DUT7 (.*);

    //****TASKS****//  
    //PC
    task test_PC;
        baz a;
        a            = new();
        a.randomize();
        in_address   = a.in_add;
		#10;
        assert(in_address == out_address);
    endtask

    //Instruction Memory
    task writemem(int i);
        baz b;
        b            = new();
        b.randomize();
        temp[i]      = b.temp;
    endtask

    task test_InstructionMemory;
        for (int i = 0; i < 10; i++) begin
            writemem(i);
        end
        $writememh("InstructionMemory.txt",temp);
        $readmemh("InstructionMemory.txt",DUT2.memory);
        for (int i = 0; i < 10; i++) begin
            Instruction_address = i * 4;
            #10;
            $display("Address: %0d | Expected: %h | Read: %h", i, temp[i], Instruction);
        end
    endtask

    //ALU
    task test_ALU;
        baz c;

        logic [31:0] expected_result;

        c            = new();
        c.randomize();
        operand1     = c.op1;
        operand2     = c.op2;
        ALUoperation = c.aluop;
        
        case(ALUoperation)
            4'b0000 : expected_result = operand1 & operand2; 
            4'b0001 : expected_result = operand1 | operand2;
            4'b0010 : expected_result = operand1 + operand2;
            4'b0110 : expected_result = operand1 - operand2;
        endcase

        #1;
        assert (ALUresult == expected_result);

        if ((ALUoperation == 4'b0110) & (ALUresult == 32'd0)) begin
            assert (zero == 1'b1);
        end
        else begin
            assert (zero == 1'b0);
        end
    endtask

    task test_ALU1;
        baz d;
        d            = new();
        d.randomize();
        operand1     = d.op1;
        operand2     = operand1;
        ALUoperation = 4'b0110;
        #1;
        assert (ALUresult == operand1 - operand2);
        assert (zero == 1'b1);
    endtask

    //Mux
    task test_Mux;
        baz e;
        e            = new();
        e.randomize();
        in1          = e.i1;
        in2          = e.i2;
        MemtoReg     = e.m2r;
        #1;
        case(MemtoReg)
            1'b0 : assert (out == in2);
            1'b1 : assert (out == in1);
        endcase
    endtask

    //Registers
    task test_Registers;
        baz f;
        f            = new();
        f.randomize();
        Read_reg1    = f.readr1;
        Read_reg2    = f.readr2;
        Write_reg    = f.writer;
        Write_data   = f.writed;
        RegWrite     = f.regw;
    endtask

    //Adder
	task test_Add;
        baz g;
        g            = new();
        g.randomize();
        operand11     = g.op11;
        operand22     = g.op22;
        #1;
        assert(Sum == operand11 + operand22);
    endtask

    //Adder2
    task test_Add2;
        baz h;
        h            = new();
        h.randomize();
        operand111   = h.op111;
        #1;
        assert(Sum1 == operand111 + 32'd4);
    endtask

    //****INITIAL BEGIN BLOCKS****// 
    //Clock Generation
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

	initial begin

	test_ALU1();
    test_InstructionMemory();
    for (int i = 0; i < 5; i++) begin
        test_Add();
        test_Add2();
        test_ALU();
        test_Mux();
        test_PC();
        #10;
    end
    for (int i = 0; i < 7; i++) begin
        test_Registers();
        #10;
        $display("Read_data1 = %h, Read_data2 = %h", Read_data1, Read_data2);
    end

	test_DM;
	tes_IM;

	end
endmodule