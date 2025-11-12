// ===================================================================
// Akkanat Custom Instruction Definitions (.td)
// ===================================================================

// 1. SUB.ABS (R-type)
// rd = abs(rs1 - rs2)
let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
def SUB_ABS : RVInst<(outs GPR:$rd), (ins GPR:$rs1, GPR:$rs2),
  "sub.abs", "$rd, $rs1, $rs2", [], InstFormatOther>, Sched<[]>
{
  bits<5> rs2;
  bits<5> rs1;
  bits<5> rd;
  let Inst{6-0}   = 0b1110111;
  let Inst{14-12} = 0b000;
  let Inst{31-25} = 0b0000000;
  let Inst{24-20} = rs2;
  let Inst{19-15} = rs1;
  let Inst{11-7} = rd;
}

// 2. AVG.FLR (I-type)
//rd = floor((rs1 + imm) / 2)
let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
def AVG_FLR : RVInst<(outs GPR:$rd), (ins GPR:$rs1, simm12:$imm),
  "avg.flr", "$rd, $rs1, ${imm}", [], InstFormatOther>, Sched<[]>
{
  bits<12> imm;
  bits<5> rs1;
  bits<5> rd;
  let Inst{6-0}   = 0b1110111;
  let Inst{14-12} = 0b100;
  let Inst{31-20} = imm;
  let Inst{19-15} = rs1;
  let Inst{11-7}  = rd;
}

// 3. MOVU (I-type)
// rd = imm (unsigned extended)
let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
def MOVU : RVInst<(outs GPR:$rd), (ins GPR:$rs1, simm12:$imm),
  "movu", "$rd, $rs1, ${imm}", [], InstFormatOther>, Sched<[]>
{
  bits<12> imm;
  bits<5> rs1;
  bits<5> rd;
  let Inst{6-0}   = 0b1110111;
  let Inst{14-12} = 0b101;
  let Inst{31-20} = imm;
  let Inst{19-15} = rs1;
  let Inst{11-7}  = rd;
}

// 4. SRT.CMP.ST (R-type)
//Compares the signed values in registers rs1 and rs2, then stores the smaller of the two values to //the memory address
//specified in rd, and the larger value to the subsequent memory address (rd + 4).
//Execute stage must take 2 cycles for this instruction.
//Assembly format: srt.cmp.st rd, rs1, rs2
//Mem[rd] = min(rs1, rs2) Mem[rd+4] = max(rs1, rs2)
let hasSideEffects = 1, mayLoad = 0, mayStore = 1 in
def SRT_CMP_ST : RVInst<(outs), (ins GPR:$rd, GPR:$rs1, GPR:$rs2),
  "srt.cmp.st", "$rd, $rs1, $rs2", [], InstFormatOther>, Sched<[]>
{
  bits<5> rs2;
  bits<5> rs1;
  bits<5> rd;
  let Inst{6-0}   = 0b1110111;
  let Inst{14-12} = 0b001;
  let Inst{31-25} = 0b0000010;
  let Inst{24-20} = rs2;
  let Inst{19-15} = rs1;
  let Inst{11-7}  = rd;
}
// 5) LD.CMP.MAX (R-type)  -- düzeltilmiş, TableGen uyumlu versiyon
let hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
def LD_CMP_MAX : RVInst<(outs GPR:$rd), (ins GPR:$rs1, GPR:$rs2),
  "ld.cmp.max", "$rd, $rs1, $rs2", [], InstFormatOther>, Sched<[]>
{
  bits<5> rs2;
  bits<5> rs1;
  bits<5> rd;

  let Inst{31-25} = 0b0000100; // funct7
  let Inst{24-20} = rs2;
  let Inst{19-15} = rs1;
  let Inst{14-12} = 0b110;     // funct3
  let Inst{11-7}  = rd;        // rd bitfield hem adresi hem de destination'ı temsil eder
  let Inst{6-0}   = 0b1110111; // opcode
}


// 6. SRCH.BIT.PTRN (R-type)
//Searchs for an 8-bit pattern on rs1 register value and if it is found, it writes "1" to the rd register, if not, writes "0".
//The 8-bit pattern is determined by the lower 8-bits of rs2 register value.
//Assembly format: srch.bit.ptrn rd, rs1, rs2
// rd = (rs1'de rs2[7:0] deseni var mı?)
let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
def SRCH_BIT_PTRN : RVInst<(outs GPR:$rd), (ins GPR:$rs1, GPR:$rs2),
  "srch.bit.ptrn", "$rd, $rs1, $rs2", [], InstFormatOther>, Sched<[]>
{
  bits<5> rs2;
  bits<5> rs1;
  bits<5> rd;
  let Inst{6-0} = 0b1110111;
  let Inst{14-12} = 0b111;
  let Inst{31-25} = 0b0001000;
  let Inst{24-20} = rs2;
  let Inst{19-15} = rs1;
  let Inst{11-7} = rd;
}

// 7. SEL.PART (Custom-type1)
//Selects 16-bit part of the value of rs1 register. If s1 select bit is "1" then it selects most significant 16-bit,
//otherwise it selects least significant 16-bit, then it writes unsigned extended selected value to rd register.
//Assembly format: sel.part rd, rs1, s1
// rd = (s1 == 1) ? rs1[31:16] : rs1[15:0]
let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
def SEL_PART : RVInst<(outs GPR:$rd), (ins GPR:$rs1, uimm1:$sl),
  "sel.part", "$rd, $rs1, ${sl}", [], InstFormatOther>, Sched<[]>
{
  bits<1> sl;
  bits<5> rs1;
  bits<5> rd;
  let Inst{6-0} = 0b1110111;
  let Inst{14-12} = 0b010;
  let Inst{31-21} = 0b10101010101;
  let Inst{20} = sl;
  let Inst{19-15} = rs1;
  let Inst{11-7}  = rd;
}

// 8. SEL.CND (Custom-type2)
// Koşullu dallanma to S2
// Opcode, Tablo 1'deki (1111111) yerine,
// 'llvm-objdump' (01111111) ile eşleşecek.
let hasSideEffects = 0, isBranch = 1, mayLoad = 0, mayStore = 0 in
def SEL_CND : RVInst<(outs), (ins GPR:$rs1, GPR:$rs2, simm12:$imm, uimm2:$s2),
  "sel.cnd", "$rs1, $rs2, ${imm}, ${s2}", [], InstFormatOther>, Sched<[]>
{
  bits<12> imm;
  bits<2> s2;
  bits<5> rs2;
  bits<5> rs1;
  // opcode: 01111111 Tabloda 11111111 diyor düzelttim. Örnektekini esas aldım.
  let Inst{6-0}   = 0b1111111;
  let Inst{14-12} = 0b000;
  let Inst{31-27} = imm{9-5};
  let Inst{26-25} = s2;
  let Inst{24-20} = rs2;
  let Inst{19-15} = rs1;
  let Inst{11-8}  = imm{4-1};
  let Inst{7}     = imm{10};
}

// 9. MAC.LD.ST (Custom-type2)
//It loads a pair of values from the memory addresses specified by rs1 and rs2, multiplies them, and adds this value
//to the value in the memory address given by immediate value. (Be aware that imm[0] = 0)
//(It should load the value from the address, do addition with this value and the product, then should store
//in the same address)
// (s2+1) kez Load, Multiply, Accumulate, Store
let hasSideEffects = 1, mayLoad = 1, mayStore = 1 in
def MAC_LD_ST : RVInst<(outs), (ins GPR:$rs1, GPR:$rs2, simm12:$imm, uimm2:$s2),
  "mac.ld.st", "$rs1, $rs2, ${imm}, ${s2}", [], InstFormatOther>, Sched<[]>
{
  bits<12> imm; // simm12'den 11 bit kullanılır (imm[10|9:5] ve imm[4:1])
  bits<2> s2;
  bits<5> rs2;
  bits<5> rs1;
  let Inst{6-0} = 0b1111111;
  let Inst{14-12} = 0b111;
  let Inst{31-27} = imm{9-5};
  let Inst{26-25} = s2;
  let Inst{24-20} = rs2;
  let Inst{19-15} = rs1;
  let Inst{11-8} = imm{4-1};
  let Inst{7} = imm{10};
}
