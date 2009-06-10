using org.mbarbon.p.runtime;
using org.mbarbon.p.values;

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
            var cu = Serializer.ReadCompilationUnit(args[0]);

            P5Code main = new Generator(runtime).Generate(null, cu);
            main.Call(runtime, Opcode.Context.SCALAR, null);
        }
    }
}