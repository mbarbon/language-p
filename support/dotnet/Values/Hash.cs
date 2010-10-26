using org.mbarbon.p.runtime;
using System.Collections.Generic;

namespace org.mbarbon.p.values
{
    public class P5Hash : IP5Any, IP5Referrable
    {
        public P5Hash(Runtime runtime)
        {
            hash = new Dictionary<string, IP5Any>();
        }

        public P5Hash(Runtime runtime, P5Array array) : this(runtime)
        {
            AssignIterator(runtime, array.GetEnumerator(runtime));
        }

        internal void SetItem(Runtime runtime, string key, IP5Any value)
        {
            hash[key] = value;
        }

        public IP5Any GetItemOrUndef(Runtime runtime, IP5Any key, bool create)
        {
            string k = key.AsString(runtime);
            IP5Any v = null;
            if (hash.TryGetValue(k, out v))
                return v;
            if (create)
            {
                v = new P5Scalar(runtime);
                hash[k] = v;

                return v;
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

        internal bool ExistsKey(Runtime runtime, string key)
        {
            return hash.ContainsKey(key);
        }

        public IP5Any Exists(Runtime runtime, IP5Any key)
        {
            string k = key.AsString(runtime);

            return new P5Scalar(runtime, hash.ContainsKey(k));
        }

        public virtual P5Scalar AsScalar(Runtime runtime) { throw new System.NotImplementedException(); }
        public virtual int AsInteger(Runtime runtime) { throw new System.NotImplementedException(); }
        public virtual double AsFloat(Runtime runtime) { throw new System.NotImplementedException(); }
        public virtual string AsString(Runtime runtime) { throw new System.NotImplementedException(); }
        public virtual bool AsBoolean(Runtime runtime) { return hash.Count != 0; }
        public virtual bool IsDefined(Runtime runtime) { return hash.Count != 0; }

        public virtual P5Handle AsHandle(Runtime runtime)
        {
            throw new System.NotImplementedException("No AsHandle for P5Hash");
        }

        public virtual int GetPos(Runtime runtime)
        {
            return 0;
        }

        public virtual IP5Any Assign(Runtime runtime, IP5Any other)
        {
            // FIXME multiple dispatch
            P5Array a = other as P5Array;
            P5Hash h = other as P5Hash;

            if (a != null)
                return AssignIterator(runtime, a.GetEnumerator(runtime));

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

        public IEnumerator<IP5Any> GetEnumerator(Runtime runtime)
        {
            foreach (var i in hash)
            {
                yield return new P5Scalar(runtime, i.Key);
                yield return i.Value;
            }
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

        public virtual IP5Any Localize(Runtime runtime)
        {
            return new P5Hash(runtime);
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
        protected Dictionary<string, IP5Any> hash;
    }
}
