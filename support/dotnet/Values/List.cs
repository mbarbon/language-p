using Runtime = org.mbarbon.p.runtime.Runtime;
using System.Collections.Generic;

namespace org.mbarbon.p.values
{   
    public class List : Array
    {    
        public List(Runtime runtime) : base(runtime)
        {
        }

        public List(Runtime runtime, IAny[] data) : base(runtime, data)
        {
        }

        public override Scalar AsScalar(Runtime runtime)
        {
            return array.Count == 0 ? null : array[array.Count - 1].AsScalar(runtime);
        }

        public override IAny Assign(Runtime runtime, IAny other)
        {
            // FIXME multiple dispatch
            Scalar s = other as Scalar;
            Array a = other as Array;
            IEnumerator<IAny> e = null;

            if (s != null)
            {
                e = new List<IAny>(new IAny[] { s }).GetEnumerator();
            }
            else if (a != null)
            {
                e = ((Array)a.Clone(runtime, 1)).GetEnumerator();
            }

            foreach (var i in this)
                i.AssignIterator(runtime, e);

            return this;
        }
    }
}
