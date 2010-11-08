using Runtime = org.mbarbon.p.runtime.Runtime;
using Opcode = org.mbarbon.p.runtime.Opcode;
using System.Collections.Generic;
using System.Collections;

namespace org.mbarbon.p.values
{
    public class P5Array : IP5Any, IP5Referrable, IEnumerable<IP5Any>, IP5Enumerable
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

        public virtual void Undef(Runtime runtime)
        {
            if (array.Count != 0)
                array = new List<IP5Any>();
        }

        public static P5Array MakeFlat(Runtime runtime, params IP5Any[] data)
        {
            var res = new P5Array(runtime);

            res.PushFlatten(data);

            return res;
        }

        public void PushFlatten(Runtime runtime, IP5Any value)
        {
            var v = value as IP5Enumerable;

            if (v != null)
            {
                var iter = v.GetEnumerator(runtime);
                while (iter.MoveNext())
                    array.Add(iter.Current);
            }
            else
                array.Add(value);
        }

        protected void PushFlatten(IP5Any[] data)
        {
            foreach (var i in data)
            {
                var l = i as P5List;

                if (l != null)
                    foreach (var li in l)
                        array.Add(li);
                else
                    array.Add(i);
            }
        }

        public int GetCount(Runtime runtime) { return array.Count; }
        public IP5Any GetItem(Runtime runtime, int i) { return array[i]; }

        public int GetItemIndex(Runtime runtime, int i, bool create)
        {
            if (i < 0 && -i > array.Count)
                return -1;
            if (i < 0)
                return array.Count + i;

            if (i < array.Count)
                return i;
            if (create)
            {
                while (array.Count <= i)
                    array.Add(new P5Scalar(runtime));
                return i;
            }
            else
                return -2;
        }

        public IP5Any GetItemOrUndef(Runtime runtime, IP5Any index, bool create)
        {
            int i = GetItemIndex(runtime, index.AsInteger(runtime), create);

            if (i == -1)
            {
                if (create)
                    throw new System.Exception("Modification of non-creatable array value attempted, subscript " + i.ToString());
                else
                    return new P5Scalar(runtime);
            }
            else if (i == -2)
                return new P5Scalar(runtime);

            return array[i];
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

        public virtual P5Handle AsHandle(Runtime runtime)
        {
            throw new System.NotImplementedException("No AsHandle for P5Array");
        }

        public virtual int GetPos(Runtime runtime)
        {
            return 0;
        }

        public virtual IP5Any Assign(Runtime runtime, IP5Any other)
        {
            AssignArray(runtime, other);

            return this;
        }

        public virtual int AssignArray(Runtime runtime, IP5Any other)
        {
            // FIXME multiple dispatch
            P5Scalar s = other as P5Scalar;
            P5Array a = other as P5Array;
            P5Hash h = other as P5Hash;
            if (s != null)
            {
                array = new List<IP5Any>(1);
                array.Add(s.Clone(runtime, 1));

                return 1;
            }
            else if (h != null)
            {
                AssignIterator(runtime, ((P5Hash)h.Clone(runtime, 1)).GetEnumerator(runtime));

                return h.GetCount(runtime) * 2;
            }
            else if (a != null)
            {
                AssignIterator(runtime, ((P5Array)a.Clone(runtime, 1)).GetEnumerator(runtime));

                return a.GetCount(runtime);
            }

            return 0;
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

        public virtual IP5Any LocalizeElement(Runtime runtime, int index)
        {
            if (index == -1)
                throw new System.Exception("Modification of non-creatable array value attempted, subscript " + index.ToString());

            var value = array[index];
            var new_value = new P5Scalar(runtime);

            array[index] = new_value;

            return value;
        }

        public virtual void RestoreElement(Runtime runtime, int index, IP5Any value)
        {
            array[index] = value;
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

        public IP5Any CallMethod(Runtime runtime, Opcode.ContextValues context,
                                 string method)
        {
            var invocant = array[0];
            var pmethod = invocant.FindMethod(runtime, method);

            if (pmethod == null)
                throw new System.Exception("Can't find method " + method);

            return pmethod.Call(runtime, context, this);
        }

        private P5SymbolTable blessed;
        protected List<IP5Any> array;
    }
}
