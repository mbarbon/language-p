using Runtime = org.mbarbon.p.runtime.Runtime;
using System.Collections.Generic;

namespace org.mbarbon.p.values
{
    public interface IP5Referrable
    {
    }

    public interface IP5Any
    {
        P5Scalar AsScalar(Runtime runtime);
        string AsString(Runtime runtime);
        int AsInteger(Runtime runtime);
        double AsFloat(Runtime runtime);
        bool AsBoolean(Runtime runtime);
        bool IsDefined(Runtime runtime);

        IP5Any Assign(Runtime runtime, IP5Any other);
        IP5Any AssignIterator(Runtime runtime, IEnumerator<IP5Any> e);
        IP5Any ConcatAssign(Runtime runtime, IP5Any other);

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
    }
}
