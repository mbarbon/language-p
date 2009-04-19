using Runtime = org.mbarbon.p.runtime.Runtime;

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
                
        public void Assign(Runtime runtime, Scalar other)
        {
            body = other.body.CloneBody(runtime);
        }

        public virtual Scalar AsScalar(Runtime runtime) { return this; }
        public virtual string AsString(Runtime runtime) { return body.AsString(runtime); }
        public virtual int AsInteger(Runtime runtime) { return body.AsInteger(runtime); }
        public virtual double AsFloat(Runtime runtime) { return body.AsFloat(runtime); }
        
        private IScalarBody body;
    }

    public interface IScalarBody
    {
        IScalarBody CloneBody(Runtime runtime);
        string AsString(Runtime runtime);
        int AsInteger(Runtime runtime);
        double AsFloat(Runtime runtime);
    }
}
