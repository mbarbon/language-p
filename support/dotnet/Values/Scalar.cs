using Runtime = org.mbarbon.p.runtime.Runtime;
using System.Collections.Generic;

namespace org.mbarbon.p.values
{
    public class P5Scalar : IP5Any
    {
        public P5Scalar(Runtime runtime) : this(new P5Undef(runtime))
        {
        }

        protected P5Scalar(IP5ScalarBody b)
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

        public virtual IP5Any Assign(Runtime runtime, IP5Any other)
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

        public virtual IP5Any ConcatAssign(Runtime runtime, IP5Any other)
        {
            P5StringNumber sn = body as P5StringNumber;
            if (sn == null || (sn.flags & P5StringNumber.HasString) == 0)
                body = sn = new P5StringNumber(runtime, body.AsString(runtime));
            else
                sn.flags = P5StringNumber.HasString;

            sn.stringValue = sn.stringValue + other.AsScalar(runtime).AsString(runtime);

            return this;
        }

        public virtual P5Scalar AsScalar(Runtime runtime) { return this; }
        public virtual string AsString(Runtime runtime) { return body.AsString(runtime); }
        public virtual int AsInteger(Runtime runtime) { return body.AsInteger(runtime); }
        public virtual double AsFloat(Runtime runtime) { return body.AsFloat(runtime); }
        public virtual bool AsBoolean(Runtime runtime) { return body.AsBoolean(runtime); }
        public virtual bool IsDefined(Runtime runtime) { return !(body is P5Undef); }

        public virtual IP5Any Clone(Runtime runtime, int depth)
        {
            return new P5Scalar(body.CloneBody(runtime));
        }

        public virtual P5Code DereferenceSubroutine(Runtime runtime)
        {
            return body.DereferenceSubroutine(runtime);
        }

        protected IP5ScalarBody body;
    }

    public interface IP5ScalarBody
    {
        IP5ScalarBody CloneBody(Runtime runtime);
        string AsString(Runtime runtime);
        int AsInteger(Runtime runtime);
        double AsFloat(Runtime runtime);
        bool AsBoolean(Runtime runtime);

        P5Code DereferenceSubroutine(Runtime runtime);
    }
}
