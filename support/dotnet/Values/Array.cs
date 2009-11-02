using Runtime = org.mbarbon.p.runtime.Runtime;
using System.Collections.Generic;

namespace org.mbarbon.p.values
{
    public class P5Array : IP5Any
    {
        public P5Array(Runtime runtime)
        {
            array = new List<IP5Any>();
        }

        public P5Array(Runtime runtime, IP5Any[] data)
        {
            array = new List<IP5Any>(data);
        }

        public P5Array(Runtime runtime, P5Array array) : this(runtime)
        {
            AssignIterator(runtime, array.GetEnumerator(runtime));
        }

        public int GetCount(Runtime runtime) { return array.Count; }
        public IP5Any GetItem(Runtime runtime, int i) { return array[i]; }
        public IP5Any GetItemOrUndef(Runtime runtime, IP5Any index)
        {
            int i = index.AsInteger(runtime);
            if (array.Count > i)
                return array[i];
            return new P5Scalar(runtime);
        }

        public IEnumerator<IP5Any> GetEnumerator(Runtime runtime)
        {
            return array.GetEnumerator();
        }

        public IEnumerator<IP5Any> GetEnumerator()
        {
            return array.GetEnumerator();
        }

        public virtual void Push(Runtime runtime, IP5Any item)
        {
            array.Add(item);
        }

        public virtual P5Scalar AsScalar(Runtime runtime) { return new P5Scalar(runtime, array.Count); }
        public virtual string AsString(Runtime runtime) { return AsScalar(runtime).AsString(runtime); }
        public virtual int AsInteger(Runtime runtime) { return array.Count; }
        public virtual double AsFloat(Runtime runtime) { return array.Count; }
        public virtual bool AsBoolean(Runtime runtime) { return array.Count != 0; }
        public virtual bool IsDefined(Runtime runtime) { return true; }

        public virtual IP5Any Assign(Runtime runtime, IP5Any other)
        {
            // FIXME multiple dispatch
            P5Scalar s = other as P5Scalar;
            P5Array a = other as P5Array;
            P5Hash h = other as P5Hash;
            if (s != null)
            {
                array = new List<IP5Any>(1);
                array[0] = s.Clone(runtime, 1);
            }
            else if (h != null)
            {
                AssignIterator(runtime, ((P5Hash)h.Clone(runtime, 1)).GetEnumerator(runtime));
            }
            else if (a != null)
            {
                AssignIterator(runtime, ((P5Array)a.Clone(runtime, 1)).GetEnumerator(runtime));
            }

            return this;
        }

        public virtual IP5Any AssignIterator(Runtime runtime, IEnumerator<IP5Any> iter)
        {
            array = new List<IP5Any>();
            while (iter.MoveNext())
                array.Add(iter.Current);

            return this;
        }

        public virtual IP5Any ConcatAssign(Runtime runtime, IP5Any other)
        {
            throw new System.InvalidOperationException();
        }

        public virtual IP5Any Clone(Runtime runtime, int depth)
        {
            P5Array clone = new P5Array(runtime);
            clone.array.Capacity = array.Count;

            for (int i = 0; i < array.Count; ++i)
            {
                if (depth == 0)
                    clone.array.Add(array[i]);
                else
                    clone.array.Add(array[i].Clone(runtime, depth - 1));
            }

            return clone;
        }

        public virtual IP5Any Localize(Runtime runtime)
        {
            return new P5Array(runtime);
        }

        public virtual P5Code DereferenceSubroutine(Runtime runtime)
        {
            throw new System.InvalidOperationException("Not a reference");
        }

        protected List<IP5Any> array;
    }
}
