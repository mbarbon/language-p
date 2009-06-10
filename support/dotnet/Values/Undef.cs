using Runtime = org.mbarbon.p.runtime.Runtime;

namespace org.mbarbon.p.values
{
    public class P5Undef : IP5ScalarBody
    {
        public P5Undef(Runtime runtime)
        {
        }

        public virtual IP5ScalarBody CloneBody(Runtime runtime)
        {
            return new P5Undef(runtime);
        }

        public virtual string AsString(Runtime runtime) { return ""; }
        public virtual int AsInteger(Runtime runtime) { return 0; }
        public virtual double AsFloat(Runtime runtime) { return 0.0; }
        public virtual bool AsBoolean(Runtime runtime) { return false; }

        public virtual P5Code DereferenceSubroutine(Runtime runtime)
        {
            throw new System.InvalidOperationException("Not a reference");
        }
    }
}
