using Runtime = org.mbarbon.p.runtime.Runtime;

namespace org.mbarbon.p.values
{
    public class Undef : IScalarBody
    {
        public Undef(Runtime runtime)
        {
        }

        public virtual IScalarBody CloneBody(Runtime runtime)
        {
            return new Undef(runtime);
        }

        public virtual string AsString(Runtime runtime) { return ""; }
        public virtual int AsInteger(Runtime runtime) { return 0; }
        public virtual double AsFloat(Runtime runtime) { return 0.0; }
        public virtual bool AsBoolean(Runtime runtime) { return false; }
    }
}
