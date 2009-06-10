using Runtime = org.mbarbon.p.runtime.Runtime;
using System.Collections.Generic;

namespace org.mbarbon.p.values
{   
    public class P5List : P5Array
    {    
        public P5List(Runtime runtime) : base(runtime)
        {
        }

        public P5List(Runtime runtime, IP5Any[] data) : base(runtime, data)
        {
        }

        public override P5Scalar AsScalar(Runtime runtime)
        {
            return array.Count == 0 ? new P5Scalar(runtime) : array[array.Count - 1].AsScalar(runtime);
        }

        public override IP5Any Assign(Runtime runtime, IP5Any other)
        {
            // FIXME multiple dispatch
            P5Scalar s = other as P5Scalar;
            P5Array a = other as P5Array;
            IEnumerator<IP5Any> e = null;

            if (s != null)
            {
                e = new List<IP5Any>(new IP5Any[] { s }).GetEnumerator();
            }
            else if (a != null)
            {
                e = ((P5Array)a.Clone(runtime, 1)).GetEnumerator();
            }

            foreach (var i in this)
                i.AssignIterator(runtime, e);

            return this;
        }
    }
}
