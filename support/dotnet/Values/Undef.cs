using Runtime = org.mbarbon.p.runtime.Runtime;
using Builtins = org.mbarbon.p.runtime.Builtins;

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
        public virtual int Length(Runtime runtime) { return 0; }

        public virtual bool IsInteger(Runtime runtime) { return true; }
        public virtual bool IsString(Runtime runtime) { return true; }
        public virtual bool IsFloat(Runtime runtime) { return true; }

        public virtual string ReferenceTypeString(Runtime runtime)
        {
            return "SCALAR";
        }

        public virtual P5Scalar DereferenceScalar(Runtime runtime)
        {
            return Builtins.SymbolicReferenceScalar(runtime, this, true);
        }

        public virtual P5Array DereferenceArray(Runtime runtime)
        {
            return Builtins.SymbolicReferenceArray(runtime, this, true);
        }

        public virtual P5Hash DereferenceHash(Runtime runtime)
        {
            return Builtins.SymbolicReferenceHash(runtime, this, true);
        }

        public virtual P5Typeglob DereferenceGlob(Runtime runtime)
        {
            throw new System.InvalidOperationException("Not a reference");
        }

        public virtual P5Code DereferenceSubroutine(Runtime runtime)
        {
            throw new System.InvalidOperationException("Not a reference");
        }

        public virtual P5Handle DereferenceHandle(Runtime runtime)
        {
            throw new System.InvalidOperationException("Not a reference");
        }

        public virtual int GetPos(Runtime runtime)
        {
            return -1;
        }

        public virtual int GetPos(Runtime runtime, out bool pos_set)
        {
            pos_set = false;

            return -1;
        }

        public virtual void SetPos(Runtime runtime, int pos, bool pos_set)
        {
            // ignored
        }
    }
}
