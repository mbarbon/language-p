using org.mbarbon.p.runtime;
using System.Collections.Generic;

namespace org.mbarbon.p.values
{
    public class P5Hash : IP5Any
    {       
        public P5Hash(Runtime runtime)
        {
            hash = new Dictionary<string, IP5Any>();
        }

        public IP5Any GetItemOrUndef(Runtime runtime, IP5Any key)
        {
            string k = key.AsString(runtime);
            IP5Any v = null;
            if (hash.TryGetValue(k, out v))
                return v;
            return new P5Scalar(runtime);
        }

        public virtual P5Scalar AsScalar(Runtime runtime) { throw new System.NotImplementedException(); }
        public virtual int AsInteger(Runtime runtime) { throw new System.NotImplementedException(); }
        public virtual double AsFloat(Runtime runtime) { throw new System.NotImplementedException(); }
        public virtual string AsString(Runtime runtime) { throw new System.NotImplementedException(); }
        public virtual bool AsBoolean(Runtime runtime) { return hash.Count != 0; }
        public virtual bool IsDefined(Runtime runtime) { return hash.Count != 0; }

        public virtual IP5Any Assign(Runtime runtime, IP5Any other)
        {
            // FIXME multiple dispatch
            P5Array a = other as P5Array;
            P5Hash h = other as P5Hash;

            if (a != null)
                return AssignIterator(runtime, a.GetEnumerator());

            hash.Clear();
            foreach (var e in h.hash)
                hash[e.Key] = e.Value.Clone(runtime, 0);

            return this;
        }

        public virtual IP5Any AssignIterator(Runtime runtime, IEnumerator<IP5Any> e)
        {
            hash.Clear();
            while (e.MoveNext())
            {
                IP5Any k = e.Current;
                e.MoveNext();
                IP5Any v = e.Current;

                hash[k.AsString(runtime)] = v;
            }

            return this;
        }

        public virtual IP5Any ConcatAssign(Runtime runtime, IP5Any other) { throw new System.InvalidOperationException(); }

        public virtual IP5Any Clone(Runtime runtime, int depth)
        {
            P5Hash clone = new P5Hash(runtime);

            foreach (var e in hash)
            {
                if (depth == 0)
                    clone.hash.Add(e.Key, e.Value);
                else
                    clone.hash.Add(e.Key, e.Value.Clone(runtime, depth - 1));
            }

            return clone;
        }

        public virtual P5Code DereferenceSubroutine(Runtime runtime)
        {
            throw new System.InvalidOperationException("Not a reference");
        }

        private Dictionary<string, IP5Any> hash;
    }
}