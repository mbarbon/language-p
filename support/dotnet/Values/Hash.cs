using org.mbarbon.p.runtime;
using System.Collections.Generic;

namespace org.mbarbon.p.values
{
    public class Hash : IAny
    {       
        public Hash(Runtime runtime)
        {
            hash = new Dictionary<string, IAny>();
        }

        public IAny GetItemOrUndef(Runtime runtime, IAny key)
        {
            string k = key.AsString(runtime);
            IAny v = null;
            if (hash.TryGetValue(k, out v))
                return v;
            return new Scalar(runtime);
        }

        public virtual Scalar AsScalar(Runtime runtime) { throw new System.NotImplementedException(); }
        public virtual int AsInteger(Runtime runtime) { throw new System.NotImplementedException(); }
        public virtual double AsFloat(Runtime runtime) { throw new System.NotImplementedException(); }
        public virtual string AsString(Runtime runtime) { throw new System.NotImplementedException(); }
        public virtual bool AsBoolean(Runtime runtime) { return hash.Count != 0; }
        public virtual bool IsDefined(Runtime runtime) { return hash.Count != 0; }

        public virtual IAny Assign(Runtime runtime, IAny other)
        {
            // FIXME multiple dispatch
            Array a = other as Array;
            Hash h = other as Hash;

            if (a != null)
                return AssignIterator(runtime, a.GetEnumerator());

            hash.Clear();
            foreach (var e in h.hash)
                hash[e.Key] = e.Value.Clone(runtime, 0);

            return this;
        }

        public virtual IAny AssignIterator(Runtime runtime, IEnumerator<IAny> e)
        {
            hash.Clear();
            while (e.MoveNext())
            {
                IAny k = e.Current;
                e.MoveNext();
                IAny v = e.Current;

                hash[k.AsString(runtime)] = v;
            }

            return this;
        }

        public virtual IAny ConcatAssign(Runtime runtime, IAny other) { throw new System.InvalidOperationException(); }

        public virtual IAny Clone(Runtime runtime, int depth)
        {
            Hash clone = new Hash(runtime);

            foreach (var e in hash)
            {
                if (depth == 0)
                    clone.hash.Add(e.Key, e.Value);
                else
                    clone.hash.Add(e.Key, e.Value.Clone(runtime, depth - 1));
            }

            return clone;
        }

        public virtual Code DereferenceSubroutine(Runtime runtime)
        {
            throw new System.InvalidOperationException("Not a reference");
        }

        private Dictionary<string, IAny> hash;
    }
}
