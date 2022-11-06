let
  mkIP = last: "fdc9:ef0a:6a3c:0::${last}/64";
in
{
  "www" = { ip = mkIP "1"; publicKey = "csMlRz8b+t1o83MZldExeOxiu7HgtW8GkbxUhZlHYXk="; };
  "kale" = { ip = mkIP "2"; publicKey = "rRL/sG/EBIp6f7upCFLq+tTpuL7ksCWABsCLVFVbwEc="; };
  "rhubarb" = { ip = mkIP "3"; publicKey = "qhdprN3mkf62ckYpgrZlg7recf9GN83kY/OYPmO/u3M="; };
  "artichoke" = { ip = mkIP "4"; publicKey = "4KfTnyv3YSe0WNR/4fi0OApNgNM3/WVWxdIlcpA75Hg="; };
}
