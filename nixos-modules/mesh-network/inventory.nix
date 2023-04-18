let
  mkIP = last: "fdc9:ef0a:6a3c:0::${last}";
in
{
  squash = { ip = mkIP "1"; publicKey = "2/iRWIJ8fFGtEdJWnwoL0caba+U9sX9v2qojMQ7OlkA="; };
  okra = { ip = mkIP "2"; publicKey = "sAZTrzkigxFIwvn7jvKTlS7E/WoD13M4zH2HZ9QwxlE="; };
  rhubarb = { ip = mkIP "3"; publicKey = "qhdprN3mkf62ckYpgrZlg7recf9GN83kY/OYPmO/u3M="; };
  kale = { ip = mkIP "4"; publicKey = "rRL/sG/EBIp6f7upCFLq+tTpuL7ksCWABsCLVFVbwEc="; };
  www = { ip = mkIP "5"; publicKey = "csMlRz8b+t1o83MZldExeOxiu7HgtW8GkbxUhZlHYXk="; };
  beetroot = { ip = mkIP "6"; publicKey = "zZ6/DxjwpSTNkZnXJGRLZExYIbdP182vVFggj1zSrmA="; };
}
