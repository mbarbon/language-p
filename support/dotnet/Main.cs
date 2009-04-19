using org.mbarbon.p.runtime;
using org.mbarbon.p.values;
using System.IO;

namespace org.mbarbon.p
{
    class MainClass
    {
        public static void Main(string[] args)
        {
            var runtime = new Runtime();

            BinaryReader reader = new BinaryReader(File.Open(args[0], FileMode.Open));
            System.Console.WriteLine(Serializer.ReadCompilationUnit(reader).ToString());
        }
    }
}