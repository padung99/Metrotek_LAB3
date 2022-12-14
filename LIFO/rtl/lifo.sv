module lifo #(
  parameter int DWIDTH        = 16,
  parameter int AWIDTH        = 8,
  parameter int ALMOST_FULL   = 2,
  parameter int ALMOST_EMPTY  = 2
)(
  input               clk_i,
  input               srst_i,

  input               wrreq_i,
  input  [DWIDTH-1:0] data_i,

  input               rdreq_i,
  output [DWIDTH-1:0] q_o,

  output              almost_empty_o,
  output              empty_o,
  output              almost_full_o,
  output              full_o,
  output [AWIDTH:0]   usedw_o
);

`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "ModelSim" , encrypt_agent_info = "10.5b"
`pragma protect key_keyowner = "Mentor Graphics Corporation" , key_keyname = "MGC-VERIF-SIM-RSA-2"
`pragma protect key_method = "rsa"
`pragma protect encoding = ( enctype = "base64" , line_length = 64 , bytes = 256 )
`pragma protect key_block
Zk4qn2gofPxpoId0TzaQ1Ca7UV4Y+NVNM46xdzoLlcHwCbmcsZVkGwKBRgMJ6una
47UZeLNhB3P7ByL0W7TgO7xpKAQR7GTYqNhliv32gYw3N/7qeqw7qDv275QX27qb
G0MR+6KMK3F6ijKWGjnqofaDuwfeNwTjiGIV0aaA0PUnIvplIUS9NWGnbp9QcQKE
NGaHCcePoT0ZtbT2qo77woaO+ksICJ2HZC/8ZonCHMk7OzIp4Bd0t09yfA91Lg1f
aZGA2RfYQL+O3eWeWEPF+aCc3rtS/A0bDojl2hjPfxdBJLG6huU1mgr+cUX/Bzfk
U/BqSnMMIGFBTmyI8EE07Q==
`pragma protect data_method = "aes128-cbc"
`pragma protect encoding = ( enctype = "base64" , line_length = 64 , bytes = 4944 )
`pragma protect data_block
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
`pragma protect end_protected
