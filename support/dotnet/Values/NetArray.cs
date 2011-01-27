using Runtime = org.mbarbon.p.runtime.Runtime;
using NetGlue = org.mbarbon.p.runtime.NetGlue;
using System.Collections.Generic;
using System.Collections;

namespace org.mbarbon.p.values
{
    public class P5NetArray : AnyBase, IP5Array
    {
        public P5NetArray(System.Collections.IList _array)
        {
            array = _array;
        }

        // IP5Any
        public override P5Scalar AsScalar(Runtime runtime) { return new P5Scalar(runtime, array.Count); }
        public override string AsString(Runtime runtime) { return AsScalar(runtime).AsString(runtime); }
        public override int AsInteger(Runtime runtime) { return array.Count; }
        public override double AsFloat(Runtime runtime) { return array.Count; }
        public override bool AsBoolean(Runtime runtime) { return array.Count != 0; }

        public override int StringLength(Runtime runtime)
        {
            return AsString(runtime).Length;
        }

        public override int GetPos(Runtime runtime) { return -1; }
        public override int GetPos(Runtime runtime, out bool pos_set)
        {
            pos_set = false;

            return -1;
        }

        public override IP5Any AssignIterator(Runtime runtime, IEnumerator<IP5Any> e)
        {
            for (int i = 0; i < array.Count; ++i)
            {
                if (e.MoveNext())
                    array[i] = NetGlue.UnwrapValue(e.Current, typeof(object));
                else
                    array[i] = null;
            }

            return this;
        }

        public override void Undef(Runtime runtime)
        {
            throw new System.NotImplementedException();
        }

        public override IP5Any Clone(Runtime runtime, int depth)
        {
            return this;
        }

        public override IP5Any Localize(Runtime runtime)
        {
            throw new System.NotImplementedException();
        }

        // IP5Array
        public int GetCount(Runtime runtime) { return array.Count; }

        public IP5Any GetItemOrUndef(Runtime runtime, IP5Any index, bool create)
        {
            int idx = index.AsInteger(runtime);

            if (create)
                return new P5NetArrayItem(array, idx);
            else
                return NetGlue.WrapValue(array[idx]);
        }

        public IP5Any GetItem(Runtime runtime, int index)
        {
            return NetGlue.WrapValue(array[index]);
        }

        public int GetItemIndex(Runtime runtime, int i, bool create)
        {
            return i;
        }

        public P5List Slice(Runtime runtime, P5Array keys, bool create)
        {
            throw new System.NotImplementedException();
        }

        public void PushFlatten(Runtime runtime, IP5Value value)
        {
            throw new System.NotImplementedException();
        }

        public P5Scalar PushList(Runtime runtime, P5Array items)
        {
            throw new System.NotImplementedException();
        }

        public P5Scalar UnshiftList(Runtime runtime, P5Array items)
        {
            throw new System.NotImplementedException();
        }

        public IP5Any PopElement(Runtime runtime)
        {
            throw new System.NotImplementedException();
        }

        public IP5Any ShiftElement(Runtime runtime)
        {
            throw new System.NotImplementedException();
        }

        public P5List Splice(Runtime runtime, int start, int length)
        {
            throw new System.NotImplementedException();
        }

        public P5List Replace(Runtime runtime, int start, int length, IP5Any[] values)
        {
            throw new System.NotImplementedException();
        }

        public IP5Any LocalizeElement(Runtime runtime, int index)
        {
            throw new System.NotImplementedException();
        }

        public void RestoreElement(Runtime runtime, int index, IP5Any value)
        {
            throw new System.NotImplementedException();
        }

        // IP5Enumerable
        public IEnumerator<IP5Any> GetEnumerator(Runtime runtime)
        {
            return GetEnumerator();
        }

        // IEnumerable<IP5Any>
        public IEnumerator<IP5Any> GetEnumerator()
        {
            foreach (var i in array)
                yield return new P5Scalar(new P5NetWrapper(i));
        }

        IEnumerator IEnumerable.GetEnumerator()
        {
            return GetEnumerator();
        }

        // IP5Referrable
        public override void Bless(Runtime runtime, P5SymbolTable stash)
        {
            throw new System.NotImplementedException();
        }

        public override  bool IsBlessed(Runtime runtime)
        {
            return false;
        }

        public override  P5SymbolTable Blessed(Runtime runtime)
        {
            return null;
        }

        public override  string ReferenceTypeString(Runtime runtime)
        {
            return "ARRAY";
        }

        private System.Collections.IList array;
    }

    public class P5NetArrayItem : P5ActiveScalar
    {
        public P5NetArrayItem(System.Collections.IList _array, int _index)
        {
            body = new P5NetArrayItemBody(_array, _index);
        }
    }

    public class P5NetArrayItemBody : P5ActiveScalarBody
    {
        public P5NetArrayItemBody(System.Collections.IList _array, int _index)
        {
            array = _array;
            index = _index;
        }

        public override void Set(Runtime runtime, IP5Any other)
        {
            array[index] = NetGlue.UnwrapValue(other, typeof(object));
        }

        public override P5Scalar Get(Runtime runtime)
        {
            return NetGlue.WrapValue(array[index]);
        }

        private System.Collections.IList array;
        private int index;
    }
}

