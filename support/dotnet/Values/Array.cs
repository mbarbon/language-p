using Runtime = org.mbarbon.p.runtime.Runtime;
using System.Collections.Generic;

namespace org.mbarbon.p.values
{
    public class Array : IAny
    {       
        public Array(Runtime runtime)
        {
            array = new List<IAny>();
        }

        public Array(Runtime runtime, IAny[] data)
        {
            array = new List<IAny>(data);
        }

        public int GetCount(Runtime runtime) { return array.Count; }
        public IAny GetItem(Runtime runtime, int i) { return array[i]; }
        public IAny GetItemOrUndef(Runtime runtime, IAny index)
        {
            int i = index.AsInteger(runtime);
            if (array.Count > i)
                return array[i];
            return new Scalar(runtime);
        }

        public IEnumerator<IAny> GetEnumerator()
        {
            return array.GetEnumerator();
        }

        public virtual void Push(Runtime runtime, IAny item)
        {
            array.Add(item);
        }
        
        public virtual Scalar AsScalar(Runtime runtime) { return new Scalar(runtime, array.Count); }
        public virtual string AsString(Runtime runtime) { return AsScalar(runtime).AsString(runtime); }
        public virtual int AsInteger(Runtime runtime) { return array.Count; }
        public virtual double AsFloat(Runtime runtime) { return array.Count; }        
        public virtual bool AsBoolean(Runtime runtime) { return array.Count != 0; }
        public virtual bool IsDefined(Runtime runtime) { return true; }

        public virtual IAny Assign(Runtime runtime, IAny other)
        {
            // FIXME multiple dispatch
            Scalar s = other as Scalar;
            Array a = other as Array;
            if (s != null)
            {
                array = new List<IAny>(1);
                array[0] = s.Clone(runtime, 1);
            }
            else if (a != null)
            {
                AssignIterator(runtime, ((Array)a.Clone(runtime, 1)).GetEnumerator());
            }

            return this;
        }

        public virtual IAny AssignIterator(Runtime runtime, IEnumerator<IAny> iter)
        {
            array = new List<IAny>();
            while (iter.MoveNext())
                array.Add(iter.Current);

            return this;
        }

        public virtual IAny ConcatAssign(Runtime runtime, IAny other)
        {
            throw new System.InvalidOperationException();
        }

        public virtual IAny Clone(Runtime runtime, int depth)
        {
            Array clone = new Array(runtime);
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

        public virtual Code DereferenceSubroutine(Runtime runtime)
        {
            throw new System.InvalidOperationException("Not a reference");
        }
        
        protected List<IAny> array;
    }
}
