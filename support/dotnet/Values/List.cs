using Runtime = org.mbarbon.p.runtime.Runtime;
using System.Collections.Generic;

namespace org.mbarbon.p.values
{
    public class P5List : P5Array
    {
        public P5List(Runtime runtime) : base(runtime)
        {
        }

        public P5List(Runtime runtime, bool value) : base(runtime)
        {
            if (value)
                array.Add(new P5Scalar(runtime, 1));
        }

        public P5List(Runtime runtime, IP5Any value) :
            base(runtime, new IP5Any[] { value })
        {
        }

        public P5List(Runtime runtime, List<IP5Any> data) : base(runtime, data)
        {
        }

        public P5List(Runtime runtime, params IP5Any[] data) : base(runtime, data)
        {
        }

        public static new P5List MakeFlat(Runtime runtime, params IP5Any[] data)
        {
            var res = new P5List(runtime);

            res.PushFlatten(data);

            return res;
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
                e = ((P5Array)a.Clone(runtime, 1)).GetEnumerator(runtime);
            }

            foreach (var i in this)
                i.AssignIterator(runtime, e);

            return this;
        }

        public P5List Slice(Runtime runtime, P5Array keys)
        {
            var res = new P5List(runtime);
            var list = new List<IP5Any>();
            bool found = false;

            foreach (var key in keys)
            {
                int i = key.AsInteger(runtime);

                found = found || i < array.Count;
                list.Add(GetItemOrUndef(runtime, key, false));
            }
            if (found)
                res.SetArray(list);

            return res;
        }
    }
}
