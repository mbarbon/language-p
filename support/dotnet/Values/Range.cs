using Runtime = org.mbarbon.p.runtime.Runtime;
using System.Collections.Generic;

namespace org.mbarbon.p.values
{
    public class P5Range : IP5Enumerable
    {
        public P5Range(Runtime runtime, int start, int end)
        {
            Start = start;
            End = end;
        }

        public IEnumerator<IP5Any> GetEnumerator(Runtime runtime)
        {
            // TODO handle the other range cases
            for (int i = Start; i <= End; ++i)
                yield return new P5Scalar(runtime, i);
        }

        public int GetCount()
        {
            return End - Start + 1;
        }

        private int Start, End;
    }
}
