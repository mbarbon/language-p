using org.mbarbon.p.values;
using System.Collections.Generic;
using Regex = System.Text.RegularExpressions.Regex;

namespace org.mbarbon.p.runtime
{
    public partial class Builtins
    {
        public static P5Scalar IsFile(Runtime runtime, IP5Any path)
        {
            var str = path.AsString(runtime);

            if (System.IO.File.Exists(str))
                return new P5Scalar(runtime, true);

            if (System.IO.Directory.Exists(str))
                return new P5Scalar(runtime, false);

            return new P5Scalar(runtime);
        }
    }
}
