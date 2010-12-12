using org.mbarbon.p.values;
using System.IO;
using System.Collections.Generic;

namespace org.mbarbon.p.runtime
{
    public partial class Builtins
    {
        public static P5Scalar Print(Runtime runtime, P5Handle handle, P5Array args)
        {
            // wrong but works well enough for now
            for (int i = 0, m = args.GetCount(runtime); i < m; ++i)
            {
                handle.Write(runtime, args.GetItem(runtime, i), 0, -1);
            }

            return new P5Scalar(runtime, 1);
        }

        public static IP5Any Readline(Runtime runtime, P5Handle handle,
                                      Opcode.ContextValues cxt)
        {
            if (cxt == Opcode.ContextValues.LIST)
            {
                P5Scalar line;
                var lines = new List<IP5Any>();

                while (handle.Readline(runtime, out line))
                    lines.Add(line);

                return new P5List(runtime, lines);
            }
            else
            {
                P5Scalar line;
                handle.Readline(runtime, out line);

                return line;
            }
        }
    }
}
