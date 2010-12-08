using Runtime = org.mbarbon.p.runtime.Runtime;
using System.Collections.Generic;

namespace org.mbarbon.p.values
{
    public class P5Scalar : IP5Any, IP5Referrable
    {
        public P5Scalar(Runtime runtime) : this(new P5Undef(runtime))
        {
        }

        public P5Scalar(IP5ScalarBody b)
        {
            body = b;
        }

        protected P5Scalar()
        {
        }

        public P5Scalar(Runtime runtime, string val) : this(new P5StringNumber(runtime, val)) {}
        public P5Scalar(Runtime runtime, int val) : this(new P5StringNumber(runtime, val)) {}
        public P5Scalar(Runtime runtime, double val) : this(new P5StringNumber(runtime, val)) {}
        public P5Scalar(Runtime runtime, bool val)
            : this(val ? new P5StringNumber(runtime, 1) : new P5StringNumber(runtime, "")) {}
        public P5Scalar(Runtime runtime, IP5Referrable val) : this(new P5Reference(runtime, val)) {}

        public virtual void Undef(Runtime runtime)
        {
            if (!(body is P5Undef))
                body = new P5Undef(runtime);
        }

        public virtual P5Scalar Assign(Runtime runtime, IP5Any other)
        {
            body = other.AsScalar(runtime).body.CloneBody(runtime);

            return this;
        }

        public virtual IP5Any AssignIterator(Runtime runtime, IEnumerator<IP5Any> iter)
        {
            if (iter.MoveNext())
                Assign(runtime, iter.Current);
            else
                body = new P5Undef(runtime);

            return this;
        }

        public P5Scalar ConcatAssign(Runtime runtime, IP5Any other)
        {
            P5StringNumber sn = body as P5StringNumber;
            if (sn == null)
                body = sn = new P5StringNumber(runtime, body.AsString(runtime));
            else
                sn.flags = P5StringNumber.HasString;

            sn.stringValue = sn.stringValue + other.AsScalar(runtime).AsString(runtime);
            sn.pos = -1;

            return this;
        }

        public virtual IP5Any SpliceSubstring(Runtime runtime,
                                              int start, int end,
                                              IP5Any replace)
        {
            P5StringNumber sn = body as P5StringNumber;
            if (sn == null)
                body = sn = new P5StringNumber(runtime, body.AsString(runtime));
            else
                sn.flags = P5StringNumber.HasString;

            // TODO handle the various corner cases for start/end
            sn.stringValue = sn.stringValue.Substring(0, start)
                + replace.AsString(runtime) + sn.stringValue.Substring(end);

            return this;
        }

        public virtual P5Scalar AsScalar(Runtime runtime) { return this; }
        public virtual string AsString(Runtime runtime) { return body.AsString(runtime); }
        public virtual int AsInteger(Runtime runtime) { return body.AsInteger(runtime); }
        public virtual double AsFloat(Runtime runtime) { return body.AsFloat(runtime); }
        public virtual bool AsBoolean(Runtime runtime) { return body.AsBoolean(runtime); }
        public virtual bool IsDefined(Runtime runtime) { return !(body is P5Undef); }

        public virtual bool IsInteger(Runtime runtime) { return body.IsInteger(runtime); }
        public virtual bool IsString(Runtime runtime) { return body.IsString(runtime); }
        public virtual bool IsFloat(Runtime runtime) { return body.IsFloat(runtime); }
        public virtual bool IsReference(Runtime runtime) { return body as P5Reference != null; }

        public virtual P5Handle AsHandle(Runtime runtime)
        {
            throw new System.NotImplementedException("No AsHandle for P5Scalar");
        }

        public void SetString(Runtime runtime, string value)
        {
            var str_num = body as P5StringNumber;

            if (str_num != null)
                str_num.SetString(runtime, value);
            else
                body = new P5StringNumber(runtime, value);
        }

        public void SetInteger(Runtime runtime, int value)
        {
            var str_num = body as P5StringNumber;

            if (str_num != null)
                str_num.SetInteger(runtime, value);
            else
                body = new P5StringNumber(runtime, value);
        }

        public void SetFloat(Runtime runtime, double value)
        {
            var str_num = body as P5StringNumber;

            if (str_num != null)
                str_num.SetFloat(runtime, value);
            else
                body = new P5StringNumber(runtime, value);
        }

        public virtual int Length(Runtime runtime)
        {
            return body.Length(runtime);
        }

        public virtual int StringLength(Runtime runtime)
        {
            return body.Length(runtime);
        }

        public P5Scalar Repeat(Runtime runtime, IP5Any c)
        {
            int count = c.AsInteger(runtime);
            string val = AsString(runtime);
            var str = new System.Text.StringBuilder();

            for (int i = 0; i < count; ++i)
                str.Append(val);

            return new P5Scalar(runtime, str.ToString());
        }

        public virtual P5Scalar PreIncrement(Runtime runtime)
        {
            var sb = body as P5StringNumber;

            if (sb != null)
                sb.Increment(runtime);
            else
                body = new P5StringNumber(runtime, body.AsInteger(runtime) + 1);

            return this;
        }

        public virtual P5Scalar PreDecrement(Runtime runtime)
        {
            var sb = body as P5StringNumber;

            if (sb != null)
                sb.Decrement(runtime);
            else
                body = new P5StringNumber(runtime, body.AsInteger(runtime) - 1);

            return this;
        }

        public virtual P5Scalar PostIncrement(Runtime runtime)
        {
            var old = Clone(runtime, 0) as P5Scalar;
            PreIncrement(runtime);

            return old;
        }

        public virtual P5Scalar PostDecrement(Runtime runtime)
        {
            var old = Clone(runtime, 0) as P5Scalar;
            PreDecrement(runtime);

            return old;
        }

        public virtual IP5Any Clone(Runtime runtime, int depth)
        {
            return new P5Scalar(body.CloneBody(runtime));
        }

        public virtual IP5Any Localize(Runtime runtime)
        {
            return new P5Scalar(runtime);
        }

        public virtual P5Scalar ReferenceType(Runtime runtime)
        {
            return body.ReferenceType(runtime);
        }

        public virtual P5Scalar DereferenceScalar(Runtime runtime)
        {
            return body.DereferenceScalar(runtime);
        }

        public virtual P5Array DereferenceArray(Runtime runtime)
        {
            return body.DereferenceArray(runtime);
        }

        public virtual P5Hash DereferenceHash(Runtime runtime)
        {
            return body.DereferenceHash(runtime);
        }

        public virtual P5Typeglob DereferenceGlob(Runtime runtime)
        {
            return body.DereferenceGlob(runtime);
        }

        public virtual P5Code DereferenceSubroutine(Runtime runtime)
        {
            return body.DereferenceSubroutine(runtime);
        }

        // must be checked by the caller
        public virtual IP5Regex DereferenceRegex(Runtime runtime)
        {
            return (body as P5Reference).Referred as IP5Regex;
        }

        // must be checked by the caller
        public virtual IP5Referrable Dereference(Runtime runtime)
        {
            return (body as P5Reference).Referred;
        }

        public virtual P5Scalar VivifyScalar(Runtime runtime)
        {
            var undef = body as P5Undef;

            if (undef != null)
                body = new P5Reference(runtime, new P5Scalar(runtime));

            return body.DereferenceScalar(runtime);
        }

        public virtual P5Array VivifyArray(Runtime runtime)
        {
            var undef = body as P5Undef;

            if (undef != null)
                body = new P5Reference(runtime, new P5Array(runtime));

            return body.DereferenceArray(runtime);
        }

        public virtual P5Hash VivifyHash(Runtime runtime)
        {
            var undef = body as P5Undef;

            if (undef != null)
                body = new P5Reference(runtime, new P5Hash(runtime));

            return body.DereferenceHash(runtime);
        }

        public virtual int GetPos(Runtime runtime)
        {
            return body.GetPos(runtime);
        }

        public virtual int GetPos(Runtime runtime, out bool pos_set)
        {
            return body.GetPos(runtime, out pos_set);
        }

        public virtual void UnsetPos(Runtime runtime)
        {
            body.SetPos(runtime, -1, false);
        }

        public virtual void SetPos(Runtime runtime, int pos, bool pos_set)
        {
            body.SetPos(runtime, pos, pos_set);
        }

        public virtual void Bless(Runtime runtime, P5SymbolTable stash)
        {
            blessed = stash;
        }

        public virtual bool IsBlessed(Runtime runtime)
        {
            return blessed != null;
        }

        public P5SymbolTable BlessedReferenceStash(Runtime runtime)
        {
            var refbody = body as P5Reference;

            return refbody != null ? refbody.Referred.Blessed(runtime) : null;
        }

        public virtual P5Code FindMethod(Runtime runtime, string method)
        {
            var refbody = body as P5Reference;
            int colon = method.LastIndexOf("::");
            P5SymbolTable stash;

            if (colon != -1)
            {
                stash = runtime.SymbolTable.GetPackage(runtime, method, true, false);
                method = method.Substring(colon + 2);
            }
            else if (refbody != null)
                stash = refbody.Referred.Blessed(runtime);
            else
                stash = runtime.SymbolTable.GetPackage(runtime, AsString(runtime), false);

            if (stash == null)
                return null;

            return stash.FindMethod(runtime, method);
        }

        internal void BlessReference(Runtime runtime, P5SymbolTable stash)
        {
            var refbody = body as P5Reference;
            if (refbody == null)
                throw new System.Exception("Not a reference");

            refbody.Referred.Bless(runtime, stash);
        }

        public virtual P5SymbolTable Blessed(Runtime runtime)
        {
            return blessed;
        }

        internal IP5ScalarBody Body
        {
            get
            {
                return body;
            }
        }

        protected P5SymbolTable blessed;
        protected IP5ScalarBody body;
    }

    public interface IP5ScalarBody
    {
        IP5ScalarBody CloneBody(Runtime runtime);
        string AsString(Runtime runtime);
        int AsInteger(Runtime runtime);
        double AsFloat(Runtime runtime);
        bool AsBoolean(Runtime runtime);
        int Length(Runtime runtime);

        bool IsInteger(Runtime runtime);
        bool IsString(Runtime runtime);
        bool IsFloat(Runtime runtime);

        int GetPos(Runtime runtime);
        int GetPos(Runtime runtime, out bool pos_set);
        void SetPos(Runtime runtime, int pos, bool pos_set);

        P5Scalar ReferenceType(Runtime runtime);

        P5Scalar DereferenceScalar(Runtime runtime);
        P5Array DereferenceArray(Runtime runtime);
        P5Hash DereferenceHash(Runtime runtime);
        P5Typeglob DereferenceGlob(Runtime runtime);
        P5Code DereferenceSubroutine(Runtime runtime);
    }
}
