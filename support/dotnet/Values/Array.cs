using Runtime = org.mbarbon.p.runtime.Runtime;
using Opcode = org.mbarbon.p.runtime.Opcode;
using Builtins = org.mbarbon.p.runtime.Builtins;
using System.Collections.Generic;
using System.Collections;

namespace org.mbarbon.p.values
{
    public interface IP5Array : IP5Any, IEnumerable<IP5Any>, IP5Enumerable
    {
        int GetCount(Runtime runtime);

        IP5Any GetItemOrUndef(Runtime runtime, IP5Any index, bool create);
        IP5Any GetItem(Runtime runtime, int i);
        int GetItemIndex(Runtime runtime, int i, bool create);
        P5List Slice(Runtime runtime, P5Array keys, bool create);

        void PushFlatten(Runtime runtime, IP5Value value);
        P5Scalar PushList(Runtime runtime, P5Array items);
        P5Scalar UnshiftList(Runtime runtime, P5Array items);
        IP5Any PopElement(Runtime runtime);
        IP5Any ShiftElement(Runtime runtime);

        P5List Splice(Runtime runtime, int start, int length);
        P5List Replace(Runtime runtime, int start, int length, IP5Any[] values);

        IP5Any LocalizeElement(Runtime runtime, int index);
        void RestoreElement(Runtime runtime, int index, IP5Any value);
    }

    public class P5Array : IP5Array
    {
        public P5Array(Runtime runtime)
        {
            array = new List<IP5Any>();
        }

        public P5Array(Runtime runtime, params IP5Any[] data)
        {
            array = new List<IP5Any>(data);
        }

        public P5Array(Runtime runtime, List<IP5Any> data)
        {
            array = data;
        }

        public P5Array(Runtime runtime, IP5Enumerable items) : this(runtime)
        {
            AssignIterator(runtime, items.GetEnumerator(runtime));
        }

        public virtual void Undef(Runtime runtime)
        {
            if (array.Count != 0)
                array = new List<IP5Any>();
        }

        public static P5Array MakeFlat(Runtime runtime, params IP5Value[] data)
        {
            var res = new P5Array(runtime);

            res.PushFlatten(runtime, data);

            return res;
        }

        public void PushFlatten(Runtime runtime, IP5Value value)
        {
            var v = value as IP5Enumerable;

            if (v != null)
            {
                var iter = v.GetEnumerator(runtime);
                while (iter.MoveNext())
                    array.Add(iter.Current);
            }
            else
                array.Add(value as IP5Any);
        }

        protected void PushFlatten(Runtime runtime, IP5Value[] data)
        {
            foreach (var i in data)
                PushFlatten(runtime, i);
        }

        public int GetCount(Runtime runtime) { return array.Count; }
        public IP5Any GetItem(Runtime runtime, int i) { return array[i]; }

        public int GetItemIndex(Runtime runtime, int i, bool create)
        {
            int idx = Builtins.GetItemIndex(runtime, array.Count, i, create);

            if (create && idx >= array.Count)
                while (array.Count <= idx)
                    array.Add(new P5Scalar(runtime));

            return idx;
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
            foreach (var item in items)
                array.Add(item.Clone(runtime, 0));

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
            var new_array = new List<IP5Any>(items.GetCount(runtime) + array.Count);

            foreach (var item in items)
                new_array.Add(item.Clone(runtime, 0));
            new_array.AddRange(array);

            array = new_array;

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
        public virtual bool IsDefined(Runtime runtime) { return array.Count != 0; }

        public virtual int StringLength(Runtime runtime)
        {
            return AsString(runtime).Length;
        }

        public virtual P5Handle DereferenceHandle(Runtime runtime)
        {
            throw new System.NotImplementedException("No DereferenceHandle for P5Array");
        }

        public virtual int GetPos(Runtime runtime)
        {
            return -1;
        }

        public virtual int GetPos(Runtime runtime, out bool pos_set)
        {
            pos_set = false;

            return -1;
        }

        public virtual int AssignArray(Runtime runtime, IP5Value other)
        {
            // FIXME multiple dispatch
            P5Scalar s = other as P5Scalar;
            P5Array a = other as P5Array;
            P5Hash h = other as P5Hash;
            P5NetArray na = other as P5NetArray;

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
            else if (na != null)
            {
                AssignIterator(runtime, na.GetEnumerator(runtime));

                return na.GetCount(runtime);
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

        public virtual string ReferenceTypeString(Runtime runtime)
        {
            return "ARRAY";
        }

        public virtual P5Scalar DereferenceScalar(Runtime runtime)
        {
            throw new System.InvalidOperationException("Not a reference");
        }

        public virtual IP5Array DereferenceArray(Runtime runtime)
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

        public virtual IP5Array VivifyArray(Runtime runtime)
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
            var invocant = array[0] as P5Scalar;

            return invocant.CallMethod(runtime, context, method, this);
        }

        public IP5Any CallMethodIndirect(Runtime runtime, Opcode.ContextValues context,
                                         P5Scalar method)
        {
            var pmethod = method.IsReference(runtime) ? method.Dereference(runtime) as P5Code : null;

            if (pmethod != null)
                return pmethod.Call(runtime, context, this);

            return CallMethod(runtime, context, method.AsString(runtime));
        }

        public P5List Repeat(Runtime runtime, IP5Any c)
        {
            int count = c.AsInteger(runtime);
            var list = new List<IP5Any>();

            for (int i = 0; i < count; ++i)
                list.AddRange(array);

            return new P5List(runtime, list);
        }

        public P5List Reversed(Runtime runtime)
        {
            var list = new List<IP5Any>(array);

            list.Reverse();

            return new P5List(runtime, list);
        }

        public P5List Splice(Runtime runtime, int start, int length)
        {
            var res = array.GetRange(start, length);

            array.RemoveRange(start, length);

            return new P5List(runtime, res);
        }

        public P5List Replace(Runtime runtime, int start, int length, IP5Any[] values)
        {
            var spliced = new List<IP5Any>();

            foreach (var i in values)
            {
                var a = i as P5Array;
                var h = i as P5Hash;
                IEnumerator<IP5Any> enumerator = null;

                if (h != null)
                    enumerator = ((P5Hash)h.Clone(runtime, 1)).GetEnumerator(runtime);
                else if (a != null)
                    enumerator = ((P5Array)a.Clone(runtime, 1)).GetEnumerator(runtime);

                if (enumerator != null)
                    while (enumerator.MoveNext())
                        spliced.Add(enumerator.Current);
                else
                    spliced.Add(i.Clone(runtime, 0));
            }

            var res = array.GetRange(start, length);

            // TODO optimize
            array.RemoveRange(start, length);
            array.InsertRange(start, spliced);

            return new P5List(runtime, res);
        }

        public P5List Sort(Runtime runtime)
        {
            var list = new List<IP5Any>(array);

            list.Sort(delegate(IP5Any a, IP5Any b)
                      {
                          return string.Compare(a.AsString(runtime),
                                                b.AsString(runtime));
                      });

            return new P5List(runtime, list);
        }

        private P5SymbolTable blessed;
        protected List<IP5Any> array;
    }
}
