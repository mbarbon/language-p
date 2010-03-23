using Runtime = org.mbarbon.p.runtime.Runtime;
using System.Collections.Generic;
using System.Collections;

namespace org.mbarbon.p.values
{
    public class P5Array : IP5Any, IP5Referrable, IEnumerable<IP5Any>
    {
        public P5Array(Runtime runtime)
        {
            array = new List<IP5Any>();
        }

        public P5Array(Runtime runtime, IP5Any[] data)
        {
            array = new List<IP5Any>(data);
        }

        public P5Array(Runtime runtime, List<IP5Any> data)
        {
            array = data;
        }

        public P5Array(Runtime runtime, P5Array array) : this(runtime)
        {
            AssignIterator(runtime, array.GetEnumerator(runtime));
        }

        public int GetCount(Runtime runtime) { return array.Count; }
        public IP5Any GetItem(Runtime runtime, int i) { return array[i]; }
        public IP5Any GetItemOrUndef(Runtime runtime, IP5Any index, bool create)
        {
            int i = index.AsInteger(runtime);

            if (i < 0 && -i > array.Count)
            {
                if (create)
                    throw new System.Exception("Modification of non-creatable array value attempted, subscript " + i.ToString());
                else
                    return new P5Scalar(runtime);
            }
            if (i < 0)
                return array[array.Count + i];

            if (i < array.Count)
                return array[i];
            if (create)
            {
                while (array.Count <= i)
                    array.Add(new P5Scalar(runtime));
                return array[i];
            }

            return new P5Scalar(runtime);
        }

        public P5List Slice(Runtime runtime, P5Array keys, bool create)
        {
            var res = new P5List(runtime);
            var list = new List<IP5Any>();

            foreach (var key in keys)
            {
                list.Add(GetItemOrUndef(runtime, key, create));
            }
            res.SetArray(list);

            return res;
        }

        public IP5Any Exists(Runtime runtime, IP5Any index)
        {
            int i = index.AsInteger(runtime);

            return new P5Scalar(runtime, (i >= 0 && i < array.Count) || (i < 0 && -i < array.Count));
        }

        public IEnumerator<IP5Any> GetEnumerator(Runtime runtime)
        {
            return array.GetEnumerator();
        }

        // implement both System.Collections.Generic.IEnumerable<T>
        // and System.Collections.IEnumerable
        public IEnumerator<IP5Any> GetEnumerator()
        {
            return array.GetEnumerator();
        }

        IEnumerator IEnumerable.GetEnumerator()
        {
            return array.GetEnumerator();
        }

        public virtual void Push(Runtime runtime, IP5Any item)
        {
            array.Add(item);
        }

        public virtual P5Scalar PushList(Runtime runtime, P5Array items)
        {
            array.AddRange(items);

            return new P5Scalar(runtime, array.Count);
        }

        public virtual IP5Any PopElement(Runtime runtime)
        {
            if (array.Count == 0)
                return new P5Scalar(runtime);
            int last = array.Count - 1;
            var e = array[last];

            array.RemoveAt(last);

            return e;
        }

        public virtual P5Scalar UnshiftList(Runtime runtime, P5Array items)
        {
            var newArray = new List<IP5Any>(items);
            newArray.AddRange(array);

            array = newArray;

            return new P5Scalar(runtime, array.Count);
        }

        public virtual IP5Any ShiftElement(Runtime runtime)
        {
            if (array.Count == 0)
                return new P5Scalar(runtime);
            var e = array[0];

            array.RemoveAt(0);

            return e;
        }

        public virtual P5Scalar AsScalar(Runtime runtime) { return new P5Scalar(runtime, array.Count); }
        public virtual string AsString(Runtime runtime) { return AsScalar(runtime).AsString(runtime); }
        public virtual int AsInteger(Runtime runtime) { return array.Count; }
        public virtual double AsFloat(Runtime runtime) { return array.Count; }
        public virtual bool AsBoolean(Runtime runtime) { return array.Count != 0; }
        public virtual bool IsDefined(Runtime runtime) { return true; }

        public virtual int GetPos(Runtime runtime)
        {
            return 0;
        }

        public virtual IP5Any Assign(Runtime runtime, IP5Any other)
        {
            // FIXME multiple dispatch
            P5Scalar s = other as P5Scalar;
            P5Array a = other as P5Array;
            P5Hash h = other as P5Hash;
            if (s != null)
            {
                array = new List<IP5Any>(1);
                array.Add(s.Clone(runtime, 1));
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

        public virtual P5Scalar ReferenceType(Runtime runtime)
        {
            return new P5Scalar(runtime);
        }

        public virtual P5Scalar DereferenceScalar(Runtime runtime)
        {
            throw new System.InvalidOperationException("Not a reference");
        }

        public virtual P5Array DereferenceArray(Runtime runtime)
        {
            throw new System.InvalidOperationException("Not a reference");
        }

        public virtual P5Hash DereferenceHash(Runtime runtime)
        {
            throw new System.InvalidOperationException("Not a reference");
        }

        public virtual P5Typeglob DereferenceGlob(Runtime runtime)
        {
            throw new System.InvalidOperationException("Not a reference");
        }

        public virtual P5Code DereferenceSubroutine(Runtime runtime)
        {
            throw new System.InvalidOperationException("Not a reference");
        }

        public virtual P5Scalar VivifyScalar(Runtime runtime)
        {
            throw new System.InvalidOperationException("Not a reference");
        }

        public virtual P5Array VivifyArray(Runtime runtime)
        {
            throw new System.InvalidOperationException("Not a reference");
        }

        public virtual P5Hash VivifyHash(Runtime runtime)
        {
            throw new System.InvalidOperationException("Not a reference");
        }

        internal void SetArray(List<IP5Any> a)
        {
            array = a;
        }

        public virtual void Bless(Runtime runtime, P5SymbolTable stash)
        {
            blessed = stash;
        }

        public virtual bool IsBlessed(Runtime runtime)
        {
            return blessed != null;
        }

        public virtual P5Code FindMethod(Runtime runtime, string method)
        {
            return blessed.FindMethod(runtime, method);
        }

        public virtual P5SymbolTable Blessed(Runtime runtime)
        {
            return blessed;
        }

        private P5SymbolTable blessed;
        protected List<IP5Any> array;
    }
}
