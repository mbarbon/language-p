using Runtime = org.mbarbon.p.runtime.Runtime;
using System.Collections.Generic;

namespace org.mbarbon.p.values
{   
    public class Scalar : IAny
    {       
        public Scalar(Runtime runtime) : this(new Undef(runtime))
        {
        }

        private Scalar(IScalarBody b)
        {
            body = b;
        }
        
        public Scalar(Runtime runtime, string val) : this(new StringNumber(runtime, val)) {}
        public Scalar(Runtime runtime, int val) : this(new StringNumber(runtime, val)) {}
        public Scalar(Runtime runtime, double val) : this(new StringNumber(runtime, val)) {}
        public Scalar(Runtime runtime, bool val)
            : this(val ? new StringNumber(runtime, 1) : new StringNumber(runtime, "")) {}
                
        public virtual IAny Assign(Runtime runtime, IAny other)
        {
            body = other.AsScalar(runtime).body.CloneBody(runtime);

            return this;
        }

        public virtual IAny AssignIterator(Runtime runtime, IEnumerator<IAny> iter)
        {
            if (iter.MoveNext())
                Assign(runtime, iter.Current);
            else
                body = new Undef(runtime);

            return this;
        }

        public virtual IAny ConcatAssign(Runtime runtime, IAny other)
        {
            StringNumber sn = body as StringNumber;
            if (sn == null || (sn.flags & StringNumber.HasString) == 0)
                body = sn = new StringNumber(runtime, body.AsString(runtime));
            else
                sn.flags = StringNumber.HasString;

            sn.stringValue = sn.stringValue + other.AsScalar(runtime).AsString(runtime);

            return this;
        }

        public virtual Scalar AsScalar(Runtime runtime) { return this; }
        public virtual string AsString(Runtime runtime) { return body.AsString(runtime); }
        public virtual int AsInteger(Runtime runtime) { return body.AsInteger(runtime); }
        public virtual double AsFloat(Runtime runtime) { return body.AsFloat(runtime); }
        public virtual bool AsBoolean(Runtime runtime) { return body.AsBoolean(runtime); }
        public virtual bool IsDefined(Runtime runtime) { return !(body is Undef); }

        public virtual IAny Clone(Runtime runtime, int depth)
        {
            return new Scalar(body.CloneBody(runtime));
        }

        private IScalarBody body;
    }

    public interface IScalarBody
    {
        IScalarBody CloneBody(Runtime runtime);
        string AsString(Runtime runtime);
        int AsInteger(Runtime runtime);
        double AsFloat(Runtime runtime);
        bool AsBoolean(Runtime runtime);
    }
}
