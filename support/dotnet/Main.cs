using org.mbarbon.p.runtime;
using org.mbarbon.p.values;
using System.IO;

using Microsoft.Linq;
using Microsoft.Linq.Expressions;
using System.Collections.Generic;

namespace org.mbarbon.p
{
    class MainClass
    {
        public static void Main(string[] args)
        {
            var runtime = new Runtime();

            BinaryReader reader = new BinaryReader(File.Open(args[0], FileMode.Open));
            var cu = Serializer.ReadCompilationUnit(reader);

            Code.Main main = (Code.Main)new Generator(runtime).Generate(cu);
            main(runtime, Opcode.Context.SCALAR, null, null);
        }
    }
}