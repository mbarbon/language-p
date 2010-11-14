using Runtime = org.mbarbon.p.runtime.Runtime;
using System.Collections.Generic;

namespace org.mbarbon.p.values
{
    public interface IP5Value
    {
    }

    public interface IP5Referrable : IP5Value
    {
        void Bless(Runtime runtime, P5SymbolTable stash);
        bool IsBlessed(Runtime runtime);
        P5SymbolTable Blessed(Runtime runtime);
    }

    public interface IP5Any : IP5Referrable
    {
        P5Scalar AsScalar(Runtime runtime);
        P5Handle AsHandle(Runtime runtime);
        string AsString(Runtime runtime);
        int AsInteger(Runtime runtime);
        double AsFloat(Runtime runtime);
        bool AsBoolean(Runtime runtime);
        bool IsDefined(Runtime runtime);

        int GetPos(Runtime runtime);

        IP5Any Assign(Runtime runtime, IP5Any other);
        IP5Any AssignIterator(Runtime runtime, IEnumerator<IP5Any> e);
        IP5Any ConcatAssign(Runtime runtime, IP5Any other);
        void Undef(Runtime runtime);

        IP5Any Clone(Runtime runtime, int depth);
        IP5Any Localize(Runtime runtime);
        P5Scalar ReferenceType(Runtime runtime);

        P5Scalar DereferenceScalar(Runtime runtime);
        P5Array DereferenceArray(Runtime runtime);
        P5Hash DereferenceHash(Runtime runtime);
        P5Typeglob DereferenceGlob(Runtime runtime);
        P5Code DereferenceSubroutine(Runtime runtime);

        P5Scalar VivifyScalar(Runtime runtime);
        P5Array VivifyArray(Runtime runtime);
        P5Hash VivifyHash(Runtime runtime);

        P5Code FindMethod(Runtime runtime, string method);
    }

    public interface IP5Enumerable : IP5Value
    {
        IEnumerator<IP5Any> GetEnumerator(Runtime runtime);
    }
}
