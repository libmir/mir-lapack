/++
Low level ndslice wrapper for LAPACK.

Attention: LAPACK and this module has column major API.

Authors: Ilya Yaroshenko
Copyright:  Copyright © 2017, Symmetry Investments & Kaleidic Associates
+/
module mir.lapack;

import mir.ndslice.slice;
import mir.ndslice.topology: retro;
import mir.ndslice.iterator;
import mir.utility: min, max;
import mir.internal.utility : realType, isComplex;

static import lapack;

public import lapack: lapackint;

@trusted pure nothrow @nogc:

/// `getri` work space query.
size_t getri_wq(T)(Slice!(T*, 2, Canonical) a)
in
{
    assert(a.length!0 == a.length!1, "getri: The input 'a' must be a square matrix.");
}
do
{
	lapackint n = cast(lapackint) a.length;
	lapackint lda = cast(lapackint) a._stride.max(1);
	T work = void;
	lapackint lwork = -1;
	lapackint info = void;

	lapack.getri_(n, null, lda, null, &work, lwork, info);

	assert(info == 0);
	return cast(size_t) work;
}

unittest
{
	alias s = getri_wq!float;
	alias d = getri_wq!double;
	alias c = getri_wq!cfloat;
	alias z = getri_wq!cdouble;
}

///
size_t getri(T)(
	Slice!(T*, 2, Canonical) a,
	Slice!(lapackint*) ipiv,
	Slice!(T*) work,
	)
in
{
	assert(a.length!0 == a.length!1, "getri: The input 'a' must be a square matrix.");
	assert(ipiv.length == a.length!0, "getri: The length of 'ipiv' must be equal to the number of rows of 'a'.");
	assert(work.length, "getri: work must have a non-zero length.");
}
do
{
	lapackint n = cast(lapackint) a.length;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint lwork = cast(lapackint) work.length;
	lapackint info = void;

	lapack.getri_(n, a.iterator, lda, ipiv.iterator, work.iterator, lwork, info);

	assert(info >= 0);
	return info;
}

unittest
{
	alias s = getri!float;
	alias d = getri!double;
	alias c = getri!cfloat;
	alias z = getri!cdouble;
}

///
size_t getrf(T)(
	Slice!(T*, 2, Canonical) a,
	Slice!(lapackint*) ipiv,
	)
in
{
    assert(ipiv.length >= min(a.length!0, a.length!1), "getrf: The length of 'ipiv' must be at least the smaller of 'a''s dimensions");
}
do
{
	lapackint m = cast(lapackint) a.length!1;
	lapackint n = cast(lapackint) a.length!0;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint info = void;

	lapack.getrf_(m, n, a.iterator, lda, ipiv.iterator, info);

	assert(info >= 0);
	return info;
}

unittest
{
	alias s = getrf!float;
	alias d = getrf!double;
	alias c = getrf!cfloat;
	alias z = getrf!cdouble;
}

///
template sptrf(T)
{
	/// `sptrf` for upper triangular input.
	size_t sptrf(
		Slice!(StairsIterator!(T*, "+")) ap,
		Slice!(lapackint*) ipiv,
		)
    in
    {
		assert(ipiv.length == ap.length, "sptrf: The length of 'ipiv' must be equal to the length 'ap'.");
    }
    do
	{
		char uplo = 'U';
		lapackint n = cast(lapackint) ap.length;
		lapackint info = void;

		lapack.sptrf_(uplo, n, &ap[0][0], ipiv.iterator, info);

		assert(info >= 0);
		return info;
	}

	/// `sptrf` for lower triangular input.
	size_t sptrf(
		Slice!(StairsIterator!(T*, "-")) ap,
		Slice!(lapackint*) ipiv,
		)
    in
    {
		assert(ipiv.length == ap.length, "sptrf: The length of 'ipiv' must be equal to the length 'ap'.");
    }
    do
	{
		char uplo = 'L';
		lapackint n = cast(lapackint) ap.length;
		lapackint info = void;

		lapack.sptrf_(uplo, n, &ap[0][0], ipiv.iterator, info);

		assert(info >= 0);
		return info;
	}
}

unittest
{
	alias s = sptrf!float;
	alias d = sptrf!double;
}

///
size_t gesv(T)(
	Slice!(T*, 2, Canonical) a,
	Slice!(lapackint*) ipiv,
	Slice!(T*, 2, Canonical) b,
	)
in
{
	assert(a.length!0 == a.length!1, "gesv: The input 'a' must be a square matrix.");
	assert(ipiv.length == a.length!0, "gesv: The length of 'ipiv' must be equal to the number of rows of 'a'.");
	assert(b.length!1 == a.length!0, "gesv: The number of columns of 'b' must equal the number of rows of 'a'");
}
do
{
	lapackint n = cast(lapackint) a.length;
	lapackint nrhs = cast(lapackint) b.length;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint ldb = cast(lapackint) b._stride.max(1);
	lapackint info = void;

	lapack.gesv_(n, nrhs, a.iterator, lda, ipiv.iterator, b.iterator, ldb, info);

	assert(info >= 0);
	return info;
}

unittest
{
	alias s = gesv!float;
	alias d = gesv!double;
}

/// `gelsd` work space query.
size_t gelsd_wq(T)(
	Slice!(T*, 2, Canonical) a,
	Slice!(T*, 2, Canonical) b,
	ref size_t liwork,
	)
	if(!isComplex!T)
in
{
    assert(b.length!1 == a.length!1, "gelsd_wq: The number of columns of 'b' must equal the number of columns of 'a'");
}
do
{
	lapackint m = cast(lapackint) a.length!1;
	lapackint n = cast(lapackint) a.length!0;
	lapackint nrhs = cast(lapackint) b.length;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint ldb = cast(lapackint) b._stride.max(1);
	T rcond = void;
	lapackint rank = void;
	T work = void;
	lapackint lwork = -1;
	lapackint iwork = void;
	lapackint info = void;

	lapack.gelsd_(m, n, nrhs, a.iterator, lda, b.iterator, ldb, null, rcond, rank, &work, lwork, &iwork, info);

	assert(info == 0);
	liwork = iwork;
	return cast(size_t) work;
}


/// ditto
size_t gelsd_wq(T)(
	Slice!(T*, 2, Canonical) a,
	Slice!(T*, 2, Canonical) b,
	ref size_t lrwork,
	ref size_t liwork,
	)
	if(isComplex!T)
in
{
    assert(b.length!1 == a.length!1, "gelsd_wq: The number of columns of 'b' must equal the number of columns of 'a'");
}
do
{
	lapackint m = cast(lapackint) a.length!1;
	lapackint n = cast(lapackint) a.length!0;
	lapackint nrhs = cast(lapackint) b.length;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint ldb = cast(lapackint) b._stride.max(1);
	realType!T rcond = void;
	lapackint rank = void;
	T work = void;
	lapackint lwork = -1;
	realType!T rwork = void;
	lapackint iwork = void;
	lapackint info = void;

	lapack.gelsd_(m, n, nrhs, a.iterator, lda, b.iterator, ldb, null, rcond, rank, &work, lwork, &rwork, &iwork, info);
	
	assert(info == 0);
	lrwork = cast(size_t)rwork;
	liwork = iwork;
	return cast(size_t) work;
}

unittest
{
	alias s = gelsd_wq!float;
	alias d = gelsd_wq!double;
	alias c = gelsd_wq!cfloat;
	alias z = gelsd_wq!cdouble;
}

///
size_t gelsd(T)(
	Slice!(T*, 2, Canonical) a,
	Slice!(T*, 2, Canonical) b,
	Slice!(T*) s,
	T rcond,
	ref size_t rank,
	Slice!(T*) work,
	Slice!(lapackint*) iwork,
	)
	if(!isComplex!T)
in
{
	assert(b.length!1 == a.length!1, "gelsd: The number of columns of 'b' must equal the number of columns of 'a'");
	assert(s.length == min(a.length!0, a.length!1), "gelsd: The length of 's' must equal the smaller of the dimensions of 'a'");
}
do
{
	lapackint m = cast(lapackint) a.length!1;
	lapackint n = cast(lapackint) a.length!0;
	lapackint nrhs = cast(lapackint) b.length;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint ldb = cast(lapackint) b._stride.max(1);
	lapackint rank_ = void;
	lapackint lwork = cast(lapackint) work.length;
	lapackint info = void;

	lapack.gelsd_(m, n, nrhs, a.iterator, lda, b.iterator, ldb, s.iterator, rcond, rank_, work.iterator, lwork, iwork.iterator, info);

	assert(info >= 0);
	rank = rank_;
	return info;
}

/// ditto
size_t gelsd(T)(
	Slice!(T*, 2, Canonical) a,
	Slice!(T*, 2, Canonical) b,
	Slice!(realType!T*) s,
	realType!T rcond,
	ref size_t rank,
	Slice!(T*) work,
	Slice!(realType!T*) rwork,
	Slice!(lapackint*) iwork,
	)
	if(isComplex!T)
in
{
	assert(b.length!1 == a.length!1, "gelsd: The number of columns of 'b' must equal the number of columns of 'a'");
	assert(s.length == min(a.length!0, a.length!1), "gelsd: The length of 's' must equal the smaller of the dimensions of 'a'");
}
do
{
	lapackint m = cast(lapackint) a.length!1;
	lapackint n = cast(lapackint) a.length!0;
	lapackint nrhs = cast(lapackint) b.length;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint ldb = cast(lapackint) b._stride.max(1);
	lapackint rank_ = void;
	lapackint lwork = cast(lapackint) work.length;
	lapackint info = void;

	lapack.gelsd_(m, n, nrhs, a.iterator, lda, b.iterator, ldb, s.iterator, rcond, rank_, work.iterator, lwork, rwork.iterator, iwork.iterator, info);

	assert(info >= 0);
	rank = rank_;
	return info;
}

unittest
{
	alias s = gelsd!float;
	alias d = gelsd!double;
	alias c = gelsd!cfloat;
	alias z = gelsd!cdouble;
}

/// `gesdd` work space query
size_t gesdd_wq(T)(
	char jobz,
	Slice!(T*, 2, Canonical) a,
	Slice!(T*, 2, Canonical) u,
	Slice!(T*, 2, Canonical) vt,
	)
{
	lapackint m = cast(lapackint) a.length!1;
	lapackint n = cast(lapackint) a.length!0;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint ldu = cast(lapackint) u._stride.max(1);
	lapackint ldvt = cast(lapackint) vt._stride.max(1);
	T work = void;
	lapackint lwork = -1;
	lapackint info = void;

	static if(!isComplex!T)
	{
		lapack.gesdd_(jobz, m, n, null, lda, null, null, ldu, null, ldvt, &work, lwork, null, info);
	}
	else
	{
		lapack.gesdd_(jobz, m, n, null, lda, null, null, ldu, null, ldvt, &work, lwork, null, null, info);
	}

	assert(info == 0);
	return cast(size_t) work;
}

unittest
{
	alias s = gesdd_wq!float;
	alias d = gesdd_wq!double;
	alias c = gesdd_wq!cfloat;
	alias z = gesdd_wq!cdouble;
}

///
size_t gesdd(T)(
	char jobz,
	Slice!(T*, 2, Canonical) a,
	Slice!(T*) s,
	Slice!(T*, 2, Canonical) u,
	Slice!(T*, 2, Canonical) vt,
	Slice!(T*) work,
	Slice!(lapackint*) iwork,
	)
	if(!isComplex!T)
{
	lapackint m = cast(lapackint) a.length!1;
	lapackint n = cast(lapackint) a.length!0;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint ldu = cast(lapackint) u._stride.max(1);
	lapackint ldvt = cast(lapackint) vt._stride.max(1);
	lapackint lwork = cast(lapackint) work.length;
	lapackint info = void;

	lapack.gesdd_(jobz, m, n, a.iterator, lda, s.iterator, u.iterator, ldu, vt.iterator, ldvt, work.iterator, lwork, iwork.iterator, info);

	assert(info >= 0);
	return info;
}

/// ditto
size_t gesdd(T)(
	char jobz,
	Slice!(T*, 2, Canonical) a,
	Slice!(realType!T*) s,
	Slice!(T*, 2, Canonical) u,
	Slice!(T*, 2, Canonical) vt,
	Slice!(T*) work,
	Slice!(realType!T*) rwork,
	Slice!(lapackint*) iwork,
	)
	if(isComplex!T)
{
	lapackint m = cast(lapackint) a.length!1;
	lapackint n = cast(lapackint) a.length!0;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint ldu = cast(lapackint) u._stride.max(1);
	lapackint ldvt = cast(lapackint) vt._stride.max(1);
	lapackint lwork = cast(lapackint) work.length;
	lapackint info = void;

	lapack.gesdd_(jobz, m, n, a.iterator, lda, s.iterator, u.iterator, ldu, vt.iterator, ldvt, work.iterator, lwork, rwork.iterator, iwork.iterator, info);

	assert(info >= 0);
	return info;
}

unittest
{
	alias s = gesdd!float;
	alias d = gesdd!double;
	alias c = gesdd!cfloat;
	alias z = gesdd!cdouble;
}

/// `gesvd` work space query
size_t gesvd_wq(T)(
	char jobu,
	char jobvt,
	Slice!(T*, 2, Canonical) a,
	Slice!(T*, 2, Canonical) u,
	Slice!(T*, 2, Canonical) vt,
	)
{
	lapackint m = cast(lapackint) a.length!1;
	lapackint n = cast(lapackint) a.length!0;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint ldu = cast(lapackint) u._stride.max(1);
	lapackint ldvt = cast(lapackint) vt._stride.max(1);
	T work = void;
	lapackint lwork = -1;
	lapackint info = void;

	static if(!isComplex!T)
	{
		lapack.gesvd_(jobu, jobvt, m, n, null, lda, null, null, ldu, null, ldvt, &work, lwork, info);
	}
	else
	{
		lapack.gesvd_(jobu, jobvt, m, n, null, lda, null, null, ldu, null, ldvt, &work, lwork, null, info);
	}

	assert(info == 0);
	return cast(size_t) work;
}

unittest
{
	alias s = gesvd_wq!float;
	alias d = gesvd_wq!double;
	alias c = gesvd_wq!cfloat;
	alias z = gesvd_wq!cdouble;
}

///
size_t gesvd(T)(
	char jobu,
	char jobvt,
	Slice!(T*, 2, Canonical) a,
	Slice!(T*) s,
	Slice!(T*, 2, Canonical) u,
	Slice!(T*, 2, Canonical) vt,
	Slice!(T*) work,
	)
	if(!isComplex!T)
{
	lapackint m = cast(lapackint) a.length!1;
	lapackint n = cast(lapackint) a.length!0;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint ldu = cast(lapackint) u._stride.max(1);
	lapackint ldvt = cast(lapackint) vt._stride.max(1);
	lapackint lwork = cast(lapackint) work.length;
	lapackint info = void;

	lapack.gesvd_(jobu, jobvt, m, n, a.iterator, lda, s.iterator, u.iterator, ldu, vt.iterator, ldvt, work.iterator, lwork, info);

	assert(info >= 0);
	return info;
}

/// ditto
size_t gesvd(T)(
	char jobu,
	char jobvt,
	Slice!(T*, 2, Canonical) a,
	Slice!(realType!T*) s,
	Slice!(T*, 2, Canonical) u,
	Slice!(T*, 2, Canonical) vt,
	Slice!(T*) work,
	Slice!(realType!T*) rwork,
	)
	if(isComplex!T)
{
	lapackint m = cast(lapackint) a.length!1;
	lapackint n = cast(lapackint) a.length!0;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint ldu = cast(lapackint) u._stride.max(1);
	lapackint ldvt = cast(lapackint) vt._stride.max(1);
	lapackint lwork = cast(lapackint) work.length;
	lapackint info = void;

	lapack.gesvd_(jobu, jobvt, m, n, a.iterator, lda, s.iterator, u.iterator, ldu, vt.iterator, ldvt, work.iterator, lwork, rwork.iterator, info);

	assert(info >= 0);
	return info;
}

unittest
{
	alias s = gesvd!float;
	alias d = gesvd!double;
	alias c = gesvd!cfloat;
	alias z = gesvd!cdouble;
}

///
template spev(T)
{
	///
	size_t spev(
		char jobz,
		Slice!(StairsIterator!(T*, "+")) ap,
		Slice!(T*) w,
		Slice!(T*, 2, Canonical) z,
		Slice!(T*) work,
		)
    in
    {
		assert(work.length == 3 * ap.length, "spev: The length of 'work' must equal three times the length of 'ap'.");
		assert(w.length == ap.length, "spev: The length of 'w' must equal the length of 'ap'.");
    }
    do
	{
		char uplo = 'U';
		lapackint n = cast(lapackint) ap.length;
		lapackint ldz = cast(lapackint) z._stride.max(1);
		lapackint info = void;

		lapack.spev_(jobz, uplo, n, &ap[0][0], w.iterator, z.iterator, ldz, work.iterator, info);

		assert(info >= 0);
		return info;
	}

	///
	size_t spev(
		char jobz,
		Slice!(StairsIterator!(T*, "-")) ap,
		Slice!(T*) w,
		Slice!(T*, 2, Canonical) z,
		Slice!(T*) work,
		)
    in
    {
		assert(work.length == 3 * ap.length, "spev: The length of 'work' must equal three times the length of 'ap'.");
		assert(w.length == ap.length, "spev: The length of 'w' must equal the length of 'ap'.");
    }
    do
	{
		char uplo = 'L';
		lapackint n = cast(lapackint) ap.length;
		lapackint ldz = cast(lapackint) z._stride.max(1);
		lapackint info = void;

		lapack.spev_(jobz, uplo, n, &ap[0][0], w.iterator, z.iterator, ldz, work.iterator, info);

		assert(info >= 0);
		return info;
	}
}

unittest
{
	alias s = spev!float;
	alias d = spev!double;
}

///
size_t sytrf(T)(
    char uplo,
    Slice!(T*, 2, Canonical) a,
    Slice!(lapackint*) ipiv,
    Slice!(T*) work,
    )
in
{
    assert(a.length!0 == a.length!1, "sytrf: The input 'a' must be a square matrix.");
}
do
{
    lapackint info = void;
    lapackint n = cast(lapackint) a.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;

    lapack.sytrf_(uplo, n, a.iterator, lda, ipiv.iterator, work.iterator, lwork, info);
    ///if info = 0: successful exit.
    ///if info > 0: if info = i, D(i, i) is exactly zero. The factorization has been
    ///completed, but the block diagonal matrix D is exactly singular, and division by
    ///zero will occur if it is used to solve a system of equations.
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return info;
}

unittest
{
	alias s = sytrf!float;
	alias d = sytrf!double;
	alias c = sytrf!cfloat;
	alias z = sytrf!cdouble;
}

///
size_t geqrf(T)(
    Slice!(T*, 2, Canonical) a,
    Slice!(T*) tau,
    Slice!(T*) work
    )
in
{
    assert(a.length!0 >= 0, "geqrf: The number of columns of 'a' must be " ~ 
        "greater than or equal to zero."); //n>=0
    assert(a.length!1 >= a.length!0, "geqrf: The number of columns of 'a' " ~ 
        "must be greater than or equal to the number of its rows."); //m>=n
    assert(tau.length >= 0, "geqrf: The input 'tau' must have length greater " ~ 
        "than or equal to zero."); //k>=0
    assert(a.length!0 >= tau.length, "geqrf: The number of columns of 'a' " ~ 
        "must be greater than or equal to the length of 'tau'."); //n>=k
    assert(work.length >= a.length!0, "geqrf: The length of 'work' must be " ~ 
        "greater than or equal to the number of rows of 'a'."); //lwork>=n
}
do
{
    lapackint m = cast(lapackint) a.length!1;
    lapackint n = cast(lapackint) a.length!0;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;
    lapackint info = void;

    lapack.geqrf_(m, n, a.iterator, lda, tau.iterator, work.iterator, lwork, info);

    ///if info == 0: successful exit;
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return info;
}

unittest
{
	alias s = geqrf!float;
	alias d = geqrf!double;
	alias c = geqrf!cfloat;
	alias z = geqrf!cdouble;
}

///
size_t getrs(T)(
    char trans,
    Slice!(T*, 2, Canonical) a,
    Slice!(T*, 2, Canonical) b,
    Slice!(lapackint*) ipiv,
    )
in
{
    assert(a.length!0 == a.length!1, "getrs: The input 'a' must be a square matrix.");
    assert(ipiv.length == a.length!0, "getrs: The length of 'ipiv' must be equal to the number of rows of 'a'.");
}
do
{
    lapackint n = cast(lapackint) a.length;
    lapackint nrhs = cast(lapackint) b.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldb = cast(lapackint) b._stride.max(1);
    lapackint info = void;

    lapack.getrs_(trans, n, nrhs, a.iterator, lda, ipiv.iterator, b.iterator, ldb, info);

    ///if info == 0: successful exit.
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return info;
}

unittest
{
	alias s = getrs!float;
	alias d = getrs!double;
	alias c = getrs!cfloat;
	alias z = getrs!cdouble;
}

///
size_t potrs(T)(
    char uplo,
    Slice!(T*, 2, Canonical) a,
    Slice!(T*, 2, Canonical) b,
    )
in
{
    assert(a.length!0 == a.length!1, "potrs: The input 'a' must be a square matrix.");
}
do
{
    lapackint n = cast(lapackint) a.length;
    lapackint nrhs = cast(lapackint) b.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldb = cast(lapackint) b._stride.max(1);
    lapackint info = void;

    lapack.potrs_(uplo, n, nrhs, a.iterator, lda, b.iterator, ldb, info);

    ///if info == 0: successful exit.
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return info;
}

unittest
{
	alias s = potrs!float;
	alias d = potrs!double;
	alias c = potrs!cfloat;
	alias z = potrs!cdouble;
}

///
size_t sytrs2(T)(
    Slice!(T*, 2, Canonical) a,
    Slice!(T*, 2, Canonical) b,
    Slice!(lapackint*) ipiv,
    Slice!(T*) work,
    char uplo,
    )
in
{
    assert(a.length!0 == a.length!1, "sytrs2: The input 'a' must be a square matrix.");
}
do
{
    lapackint n = cast(lapackint) a.length;
    lapackint nrhs = cast(lapackint) b.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldb = cast(lapackint) b._stride.max(1);
    lapackint info = void;

    lapack.sytrs2_(uplo, n, nrhs, a.iterator, lda, ipiv.iterator, b.iterator, ldb, work.iterator, info);

    ///if info == 0: successful exit.
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return info;
}

unittest
{
	alias s = sytrs2!float;
	alias d = sytrs2!double;
	alias c = sytrs2!cfloat;
	alias z = sytrs2!cdouble;
}

///
size_t geqrs(T)(
    Slice!(T*, 2, Canonical) a,
    Slice!(T*, 2, Canonical) b,
    Slice!(T*) tau,
    Slice!(T*) work
    )
in
{
    assert(a.length!0 >= 0, "geqrs: The number of columns of 'a' must be " ~ 
        "greater than or equal to zero."); //n>=0
    assert(a.length!1 >= a.length!0, "geqrs: The number of columns of 'a' " ~ 
        "must be greater than or equal to the number of its rows."); //m>=n
    assert(tau.length >= 0, "geqrs: The input 'tau' must have length greater " ~ 
        "than or equal to zero."); //k>=0
    assert(a.length!0 >= tau.length, "geqrs: The number of columns of 'a' " ~ 
        "must be greater than or equal to the length of 'tau'."); //n>=k
    assert(work.length >= a.length!0, "geqrs: The length of 'work' must be " ~ 
        "greater than or equal to the number of rows of 'a'."); //lwork>=n
}
body
{
    lapackint m = cast(lapackint) a.length!1;
    lapackint n = cast(lapackint) a.length!0;
    lapackint nrhs = cast(lapackint) b.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldb = cast(lapackint) b._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;
    lapackint info = void;

    lapack.geqrs_(m, n, nrhs, a.iterator, lda, tau.iterator, b.iterator, ldb, work.iterator, lwork, info);

    ///if info == 0: successful exit.
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return info;
}

version(none) unittest
{
	alias s = geqrs!float;
	alias d = geqrs!double;
	alias c = geqrs!cfloat;
	alias z = geqrs!cdouble;
}

///
size_t sysv_rook_wk(T)(
	char uplo,
	Slice!(T*, 2, Canonical) a,
	Slice!(T*, 2, Canonical) b,
	) 
in
{
	assert(a.length!0 == a.length!1, "sysv_rook_wk: The input 'a' must be a square matrix.");
	assert(b.length!1 == a.length!0, "sysv_rook_wk: The number of columns of 'b' must equal the number of rows of 'a'.");
}
do
{
	lapackint n = cast(lapackint) a.length;
	lapackint nrhs = cast(lapackint) b.length;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint ldb = cast(lapackint) b._stride.max(1);
	T work = void;
	lapackint lwork = -1;
	lapackint info = void;

	lapack.sysv_rook_(uplo, n, nrhs, a._iterator, lda, null, b._iterator, ldb, &work, lwork, info);

	return cast(size_t) work;
}

unittest
{
	alias s = sysv_rook_wk!float;
	alias d = sysv_rook_wk!double;
	alias c = sysv_rook_wk!cfloat;
	alias z = sysv_rook_wk!cdouble;
}

///
size_t sysv_rook(T)(
	char uplo,
	Slice!(T*, 2, Canonical) a,
	Slice!(lapackint*) ipiv,
	Slice!(T*, 2, Canonical) b,
	Slice!(T*) work,
	)
in
{
	assert(a.length!0 == a.length!1, "sysv_rook: The input 'a' must be a square matrix.");
	assert(ipiv.length == a.length!0, "sysv_rook: The length of 'ipiv' must be equal to the number of rows of 'a'");
	assert(b.length!1 == a.length!0, "sysv_rook: The number of columns of 'b' must equal the number of rows of 'a'.");
}
do
{
	lapackint n = cast(lapackint) a.length;
	lapackint nrhs = cast(lapackint) b.length;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint ldb = cast(lapackint) b._stride.max(1);
	lapackint lwork = cast(lapackint) work.length;
	lapackint info = void;

	lapack.sysv_rook_(uplo, n, nrhs, a._iterator, lda, ipiv._iterator, b._iterator, ldb, work._iterator, lwork, info);

	assert(info >= 0);
	return info;
}

unittest
{
	alias s = sysv_rook!float;
	alias d = sysv_rook!double;
	alias c = sysv_rook!cfloat;
	alias z = sysv_rook!cdouble;
}

///
size_t syev_wk(T)(
	char jobz,
	char uplo,
	Slice!(T*, 2, Canonical) a,
	Slice!(T*) w,
	)
in
{
	assert(a.length!0 == a.length!1, "syev_wk: The input 'a' must be a square matrix.");
	assert(w.length == a.length!0, "syev_wk: The length of 'w' must equal the number of rows of 'a'.");
}
do
{
	lapackint n = cast(lapackint) a.length;
	lapackint lda = cast(lapackint) a._stride.max(1);
	T work = void;
	lapackint lwork = -1;
	lapackint info = void;

	lapack.syev_(jobz, uplo, n, a._iterator, lda, w._iterator, &work, lwork, info);

	return cast(size_t) work;
}

unittest
{
	alias s = syev_wk!float;
	alias d = syev_wk!double;
}

///
size_t syev(T)(
	char jobz,
	char uplo,
	Slice!(T*, 2, Canonical) a,
	Slice!(T*) w,
	Slice!(T*) work,
	)
in
{
	assert(a.length!0 == a.length!1, "syev: The input 'a' must be a square matrix.");
	assert(w.length == a.length!0, "syev: The length of 'w' must equal the number of rows of 'a'.");
}
do
{
	lapackint n = cast(lapackint) a.length;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint lwork = cast(lapackint) work.length;
	lapackint info = void;

	lapack.syev_(jobz, uplo, n, a._iterator, lda, w._iterator, work._iterator, lwork, info);

	assert(info >= 0);
	return info;
}

unittest
{
	alias s = syev!float;
	alias d = syev!double;
}

///
size_t syev_2stage_wk(T)(
	char jobz,
	char uplo,
	Slice!(T*, 2, Canonical) a,
	Slice!(T*) w,
	)
in
{
	assert(a.length!0 == a.length!1, "syev_2stage_wk: The input 'a' must be a square matrix.");
	assert(w.length == a.length, "syev_2stage_wk: The length of 'w' must equal the number of rows of 'a'.");
}
do
{
	lapackint n = cast(lapackint) a.length;
	lapackint lda = cast(lapackint) a._stride.max(1);
	T work = void;
	lapackint lwork = -1;
	lapackint info = void;

	lapack.syev_2stage_(jobz, uplo, n, a._iterator, lda, w._iterator, &work, lwork, info);

	return cast(size_t) work;
}

version(none)
unittest
{
	alias s = syev_2stage_wk!float;
	alias d = syev_2stage_wk!double;
}

///
size_t syev_2stage(T)(
	char jobz,
	char uplo,
	Slice!(T*, 2, Canonical) a,
	Slice!(T*) w,
	Slice!(T*) work,
	)
in
{
	assert(a.length!0 == a.length!1, "syev_2stage: The input 'a' must be a square matrix.");
	assert(w.length == a.length, "syev_2stage: The length of 'w' must equal the number of rows of 'a'.");
}
do
{
	lapackint n = cast(lapackint) a.length;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint lwork = cast(lapackint) work.length;
	lapackint info = void;

	lapack.syev_2stage_(jobz, uplo, n, a._iterator, lda, w._iterator, work._iterator, lwork, info);

	assert(info >= 0);
	return info;
}

version(none)
unittest
{
	alias s = syev_2stage!float;
	alias d = syev_2stage!double;
}

///
size_t potrf(T)(
       char uplo,
       Slice!(T*, 2, Canonical) a,
       )
in
{
    assert(a.length!0 == a.length!1, "potrf: The input 'a' must be a square matrix.");
}
do
{
    lapackint n = cast(lapackint) a.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint info = void;
    
    lapack.potrf_(uplo, n, a.iterator, lda, info);
    
    assert(info >= 0);
    
    return info;
}

unittest
{
	alias s = potrf!float;
	alias d = potrf!double;
	alias c = potrf!cfloat;
	alias z = potrf!cdouble;
}

///
size_t pptrf(T)(
	char uplo,
	Slice!(T*, 2, Canonical) ap,
	)
{
	lapackint n = cast(lapackint) ap.length;
	lapackint info = void;
	
	lapack.pptrf_(uplo, n, ap.iterator, info);
	
	assert(info >= 0);
	
	return info;
}

unittest
{
	alias s = pptrf!float;
	alias d = pptrf!double;
	alias c = pptrf!cfloat;
	alias z = pptrf!cdouble;
}

///
template sptri(T)
{
	/// `sptri` for upper triangular input.
	size_t sptri(
		Slice!(StairsIterator!(T*, "+")) ap,
		Slice!(lapackint*) ipiv,
		Slice!(T*) work
		)
    in
    {
		assert(ipiv.length == ap.length, "sptri: The length of 'ipiv' must be equal to the length of 'ap'.");
		assert(work.length == ap.length, "sptri: The length of 'work' must be equal to the length of 'ap'.");
    }
    do
	{
		lapackint n = cast(lapackint) ap.length;
		lapackint info = void;

		char uplo = 'U';
		lapack.sptri_(uplo, n, &ap[0][0], ipiv.iterator, work.iterator, info);

		assert(info >= 0);
		return info;
	}

	/// `sptri` for lower triangular input.
	size_t sptri(
		Slice!(StairsIterator!(T*, "-")) ap,
		Slice!(lapackint*) ipiv,
		Slice!(T*) work
		)
    in
    {
		assert(ipiv.length == ap.length, "sptri: The length of 'ipiv' must be equal to the length of 'ap'.");
		assert(work.length == ap.length, "sptri: The length of 'work' must be equal to the length of 'ap'.");
    }
    do
	{
		lapackint n = cast(lapackint) ap.length;
		lapackint info = void;

		char uplo = 'L';
		lapack.sptri_(uplo, n, &ap[0][0], ipiv.iterator, work.iterator, info);

		assert(info >= 0);
		return info;
	}
}

unittest
{
	alias s = sptri!float;
	alias d = sptri!double;
	alias c = sptri!cfloat;
	alias z = sptri!cdouble;
}

///
size_t potri(T)(
    char uplo,
	Slice!(T*, 2, Canonical) a,
	)
in
{
    assert(a.length!0 == a.length!1, "potri: The input 'a' must be a square matrix.");
}
do
{
	lapackint n = cast(lapackint) a.length;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint info = void;

	lapack.potri_(uplo, n, a.iterator, lda, info);

	assert(info >= 0);
	return info;
}

unittest
{
	alias s = potri!float;
	alias d = potri!double;
	alias c = potri!cfloat;
	alias z = potri!cdouble;
}

///
template pptri(T)
{
	/// `pptri` for upper triangular input.
	size_t pptri(
		Slice!(StairsIterator!(T*, "+")) ap
		)
	{
		lapackint n = cast(lapackint) ap.length;
		lapackint info = void;

		char uplo = 'U';
		lapack.pptri_(uplo, n, &ap[0][0], info);

		assert(info >= 0);
		return info;
	}

	/// `pptri` for lower triangular input.
	size_t pptri(
		Slice!(StairsIterator!(T*, "-")) ap
		)
	{
		lapackint n = cast(lapackint) ap.length;
		lapackint info = void;

		char uplo = 'L';
		lapack.pptri_(uplo, n, &ap[0][0], info);

		assert(info >= 0);
		return info;
	}
}

unittest
{
	alias s = pptri!float;
	alias d = pptri!double;
	alias c = pptri!cfloat;
	alias z = pptri!cdouble;
}

///
size_t trtri(T)(
    char uplo,
    char diag,
	Slice!(T*, 2, Canonical) a,
	)
in
{
    assert(a.length!0 == a.length!1, "trtri: The input 'a' must be a square matrix.");
}
do
{
	lapackint n = cast(lapackint) a.length;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint info = void;

	lapack.trtri_(uplo, diag, n, a.iterator, lda, info);

	assert(info >= 0);
	return info;
}

unittest
{
	alias s = trtri!float;
	alias d = trtri!double;
	alias c = trtri!cfloat;
	alias z = trtri!cdouble;
}

///
template tptri(T)
{
	/// `tptri` for upper triangular input.
	size_t tptri(
		char diag,
		Slice!(StairsIterator!(T*, "+")) ap,
		)
	{
		lapackint n = cast(lapackint) ap.length;
		lapackint info = void;

		char uplo = 'U';
		lapack.tptri_(uplo, diag, n, &ap[0][0], info);

		assert(info >= 0);
		return info;
	}

	/// `tptri` for lower triangular input.
	size_t tptri(
		char diag,
		Slice!(StairsIterator!(T*, "-")) ap,
		)
	{
		lapackint n = cast(lapackint) ap.length;
		lapackint info = void;

		char uplo = 'L';
		lapack.tptri_(uplo, diag, n, &ap[0][0], info);

		assert(info >= 0);
		return info;

	}
}

unittest
{
	alias s = tptri!float;
	alias d = tptri!double;
	alias c = tptri!cfloat;
	alias z = tptri!cdouble;
}

///
size_t ormqr(T)(
    char side,
    char trans,
    Slice!(T*, 2, Canonical) a,
    Slice!(T*) tau,
    Slice!(T*, 2, Canonical) c,
    Slice!(T*) work,
    )
{
    lapackint m = cast(lapackint) c.length!1;
    lapackint n = cast(lapackint) c.length!0;
    lapackint k = cast(lapackint) tau.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldc = cast(lapackint) c._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;
    lapackint info = void;

    lapack.ormqr_(side, trans, m, n, k, a.iterator, lda, tau.iterator, c.iterator, ldc, work.iterator, lwork, info);

    ///if info == 0: successful exit.
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return info;
}

unittest
{
	alias s = ormqr!float;
	alias d = ormqr!double;
}

///
size_t unmqr(T)(
    char side,
    char trans,
    Slice!(T*, 2, Canonical) a,
    Slice!(T*) tau,
    Slice!(T*, 2, Canonical) c,
    Slice!(T*) work,
    )
{
    lapackint m = cast(lapackint) c.length!1;
    lapackint n = cast(lapackint) c.length!0;
    lapackint k = cast(lapackint) tau.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldc = cast(lapackint) c._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;
    lapackint info = void;

    lapack.unmqr_(side, trans, m, n, k, a.iterator, lda, tau.iterator, c.iterator, ldc, work.iterator, lwork, info);

    ///if info == 0: successful exit.
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return info;
}

unittest
{
    alias s = unmqr!cfloat;
    alias d = unmqr!cdouble;
}

///
size_t orgqr(T)(
    Slice!(T*, 2, Canonical) a,
    Slice!(T*) tau,
    Slice!(T*) work,
    )
in
{
    assert(a.length!0 >= 0, "orgqr: The number of columns of 'a' must be " ~ 
        "greater than or equal to zero."); //n>=0
    assert(a.length!1 >= a.length!0, "orgqr: The number of columns of 'a' " ~ 
        "must be greater than or equal to the number of its rows."); //m>=n
    assert(tau.length >= 0, "orgqr: The input 'tau' must have length greater " ~ 
        "than or equal to zero."); //k>=0
    assert(a.length!0 >= tau.length, "orgqr: The number of columns of 'a' " ~ 
        "must be greater than or equal to the length of 'tau'."); //n>=k
    assert(work.length >= a.length!0, "orgqr: The length of 'work' must be " ~ 
        "greater than or equal to the number of rows of 'a'."); //lwork>=n
}
do
{
    lapackint m = cast(lapackint) a.length!1;
    lapackint n = cast(lapackint) a.length!0;
    lapackint k = cast(lapackint) tau.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;
    lapackint info = void;

    lapack.orgqr_(m, n, k, a.iterator, lda, tau.iterator, work.iterator, lwork, info);

    ///if info == 0: successful exit.
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return info;
}

unittest
{
    alias s = orgqr!float;
    alias d = orgqr!double;
}

///
size_t ungqr(T)(
    Slice!(T*, 2, Canonical) a,
    Slice!(T*) tau,
    Slice!(T*) work,
    )
in
{
    assert(a.length!1 >= a.length!0, "ungqr: The number of columns of 'a' must be greater than or equal to the number of its rows."); //m>=n
    assert(a.length!0 >= tau.length, "ungqr: The number of columns of 'a' must be greater than or equal to the length of 'tau'."); //n>=k
    assert(work.length >= a.length!0, "ungqr: The length of 'work' must be greater than or equal to the number of rows of 'a'."); //lwork>=n
}
do
{
    lapackint m = cast(lapackint) a.length!1;
    lapackint n = cast(lapackint) a.length!0;
    lapackint k = cast(lapackint) tau.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;
    lapackint info = void;

    lapack.ungqr_(m, n, k, a.iterator, lda, tau.iterator, work.iterator, lwork, info);

    ///if info == 0: successful exit.
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return info;
}

unittest
{
    alias s = ungqr!cfloat;
    alias d = ungqr!cdouble;
}

alias orghr = unghr; // this is the name for the real type vairant of ungqr

///
size_t unghr(T)(
    Slice!(T*, 2, Canonical) a,
    Slice!(T*) tau,
    Slice!(T*) work,
)
in
{
    assert(a.length!1 >= a.length!0); //m>=n
    assert(a.length!0 >= tau.length); //n>=k
    assert(work.length >= a.length!0); //lwork>=n
}
do
{
    lapackint m = cast(lapackint) a.length!1;
    lapackint n = cast(lapackint) a.length!0;
    lapackint k = cast(lapackint) tau.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;
    lapackint info = void;
    static if (isComplex!T){
        lapack.ungqr_(m, n, k, a.iterator, lda, tau.iterator, work.iterator, lwork, info);
    }
    else { 
        lapack.orgqr_(m, n, k, a.iterator, lda, tau.iterator, work.iterator, lwork, info);
    }

    ///if info == 0: successful exit.
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return cast(size_t)info;
}

unittest
{
    alias orghrf = orghr!float;
    alias orghrd = orghr!double;
    alias unghrf = unghr!float;
    alias unghrd = unghr!double;
    alias unghrcf = unghr!cfloat;
    alias unghrcd = unghr!cdouble;
}

///
size_t gehrd(T)(
    Slice!(T*, 2, Canonical) a,
    Slice!(T*) tau,
    Slice!(T*) work,
    lapackint* ilo,
    lapackint* ihi
)
in
{
    assert(a.length!1 >= a.length!0, "gehrd: The number of columns of 'a' must be greater than or equal to the number of its rows."); //m>=n
    assert(a.length!0 >= tau.length, "gehrd: The number of columns of 'a' must be greater than or equal to the length of 'tau'."); //n>=k
    assert(work.length >= a.length!0, "gehrd: The length of 'work' must be greater than or equal to the number of rows of 'a'."); //lwork>=n
}
do
{
    lapackint n = cast(lapackint) a.length!0;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;
    lapackint info = void;    
    lapack.gehrd_(n, ilo, ihi, a.iterator, lda, tau.iterator, work.iterator, lwork, info);
    ///if info == 0: successful exit.
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return cast(size_t)info;
}

unittest
{
    alias s = gehrd!cfloat;
    alias d = gehrd!cdouble;
}

size_t hsein(T)(
    char side,
    char eigsrc,
    char initv,
    lapackint* select, //actually a logical bitset stored in here
    Slice!(T*, 2, Canonical) h,
    Slice!(T*) wr,
    Slice!(T*) wi,
    Slice!(T*, 2, Canonical) vl,
    Slice!(T*, 2, Canonical) vr,
    lapackint* m,
    Slice!(T*) work,
    lapackint* ifaill,
    lapackint* ifailr,
    lapackint* ilo,
    lapackint* ihi,
)
    if (!isComplex!T)
in
{
    assert(h.length!1 >= h.length!0, "hsein: The number of columns of 'h' " ~ 
           "must be greater than or equal to the number of its rows."); //m>=n
    assert(wr.length >= 1, "hsein: The input 'wr' must have length greater " ~ 
           "than or equal to one.");
    assert(wr.length >= h.length!0, "hsein: The input 'wr' must have length greater " ~ 
           "than or equal to the number of rows of 'h'.");
    assert(wr.length >= 1.0, "hsein: The input 'wr' must have length greater " ~ 
           "than or equal to 1.");
    assert(wi.length >= 1, "hsein: The input 'wi' must have length greater " ~ 
           "than or equal to one.");
    assert(wi.length >= h.length!0, "hsein: The input 'wi' must have length greater " ~ 
           "than or equal to the number of rows of 'h'.");
    assert(wi.length >= 1.0, "hsein: The input 'wi' must have length greater " ~ 
           "than or equal to 1.");
    assert(work.length >= h.length!0 * (h.length!0 + 2), "hsein: The length of 'work' must be " ~ 
           "greater than or equal to the square of the number of rows of 'h' plus two additional rows for real types.");
    assert(side == 'R' || side == 'L' || side == 'B', "hsein: The char, 'side' must be " ~ 
           "one of 'R', 'L' or 'B'.");
    assert(eigsrc == 'Q' || eigsrc == 'N', "hsein: The char, 'eigsrc', must be " ~
           "one of 'Q' or 'R'.");
    assert(initv == 'N' || initv == 'U', "hsein: The char, 'initv', must be " ~
           "one of 'N' or 'U'.");
    assert(side != 'L' || side != 'B' || vl.length!1 >= 1, "hsein: Slice 'vl' must be" ~
           "at least the size of '1' when 'side' is set to 'L' or 'B'.");
    assert(side != 'R' || vl.length!1 >= 1, "hsein: Slice 'vl' must be" ~
           "length greater than 1 when 'side' is 'R'.");
    assert(side != 'R' || side != 'B' || vr.length!1 >= 1, "hsein: Slice 'vr' must be" ~
           "at least the size of '1' when 'side' is set to 'R' or 'B'.");
    assert(side != 'L' || vl.length!1 >= 1, "hsein: Slice 'vr' must be" ~
           "length greater than 1 when 'side' is 'L'.");
}
do 
{
    lapackint info;
    lapackint mm = cast(lapackint) vl.length!1;
    lapackint n = cast(lapackint) h.length!0;
    lapackint ldh = cast(lapackint) h._stride.max(1);
    lapackint ldvl = cast(lapackint) vl._stride.max(1);
    lapackint ldvr = cast(lapackint) vr._stride.max(1);
    //need to seperate these methods then probably provide a wrap which does this as that's the easiest way without bloating the base methods
    lapack.hsein_(side, eigsrc, initv, select, n, h.iterator, ldh, wr.iterator, wi.iterator, vl.iterator, ldvl, vr.iterator, ldvr, &mm, *m, work.iterator, ifaill, ifailr, info);
    assert(info >= 0);
    ///if any of ifaill or ifailr entries are non-zero then that has failed to converge.
    ///ifail?[i] = j > 0 if the eigenvector stored in the i-th column of v?, coresponding to the jth eigenvalue, fails to converge.
    assert(*ifaill == 0);
    assert(*ifailr == 0);
    return info;
}

size_t hsein(T, realT)(
    char side,
    char eigsrc,
    char initv,
    lapackint* select, //actually a logical bitset stored in here
    Slice!(T*, 2, Canonical) h,
    Slice!(T*) w,
    Slice!(T*, 2, Canonical) vl,
    Slice!(T*, 2, Canonical) vr,
    lapackint* m,
    Slice!(T*) work,
    Slice!(realT*) rwork,
    lapackint* ifaill,
    lapackint* ifailr,
    lapackint* ilo,
    lapackint* ihi,
)
    if (isComplex!T && is(realType!T == realT))
in
{
    assert(h.length!1 >= h.length!0, "hsein: The number of columns of 'h' " ~ 
           "must be greater than or equal to the number of its rows."); //m>=n
    assert(w.length >= 1, "hsein: The input 'w' must have length greater " ~ 
           "than or equal to one.");
    assert(w.length >= h.length!0, "hsein: The input 'w' must have length greater " ~ 
           "than or equal to the number of rows of 'h'.");
    assert(w.length >= 1.0, "hsein: The input 'w' must have length greater " ~ 
           "than or equal to 1.");
    assert(work.length >= h.length!0 * h.length!0, "hsein: The length of 'work' must be " ~ 
           "greater than or equal to the square of the number of rows of 'h' for complex types.");
    assert(side == 'R' || side == 'L' || side == 'B', "hsein: The char, 'side' must be " ~ 
           "one of 'R', 'L' or 'B'.");
    assert(eigsrc == 'Q' || eigsrc == 'N', "hsein: The char, 'eigsrc', must be " ~
           "one of 'Q' or 'R'.");
    assert(initv == 'N' || initv == 'U', "hsein: The char, 'initv', must be " ~
           "one of 'N' or 'U'.");
    assert(side != 'L' || side != 'B' || vl.length!1 >= 1, "hsein: Slice 'vl' must be" ~
           "at least the size of '1' when 'side' is set to 'L' or 'B'.");
    assert(side != 'R' || vl.length!1 >= 1, "hsein: Slice 'vl' must be" ~
           "length greater than 1 when 'side' is 'R'.");
    assert(side != 'R' || side != 'B' || vr.length!1 >= 1, "hsein: Slice 'vr' must be" ~
           "at least the size of '1' when 'side' is set to 'R' or 'B'.");
    assert(side != 'L' || vl.length!1 >= 1, "hsein: Slice 'vr' must be" ~
           "length greater than 1 when 'side' is 'L'.");
}
do {
    lapackint n = cast(lapackint) h.length!0;
    lapackint ldh = cast(lapackint) h._stride.max(1);
    lapackint ldvl = cast(lapackint) vl._stride.max(1);
    lapackint ldvr = cast(lapackint) vr._stride.max(1);
    lapackint mm = cast(lapackint) vl.length!1;
    lapackint info = void;
    //could compute mm and m from vl and/or vr and T
    lapack.hsein_(side, eigsrc, initv, select, n, h.iterator, ldh, w.iterator, vl.iterator, ldvl, vr.iterator, ldvr, &mm, *m, work.iterator, rwork.iterator, ifaill, ifailr, info);
    assert(info >= 0);
    ///if any of ifaill or ifailr entries are non-zero then that has failed to converge.
    ///ifail?[i] = j > 0 if the eigenvector stored in the i-th column of v?, coresponding to the jth eigenvalue, fails to converge.
    assert(*ifaill == 0);
    assert(*ifailr == 0);
    return info;
}


unittest
{
    alias f = hsein!(float);
    alias d = hsein!(double);
    alias s = hsein!(cfloat,float);
    alias c = hsein!(cdouble,double);
}

alias ormhr = unmhr;

///
size_t unmhr(T)(
    char side,
    char trans,
    Slice!(T*, 2, Canonical) a,
    Slice!(T*) tau,
    Slice!(T*, 2, Canonical) c,
    Slice!(T*) work,
    lapackint* ilo,
    lapackint* ihi
)
in
{
    assert(a.length!0 >= 0, "ormhr: The number of columns of 'a' must be " ~ 
           "greater than or equal to zero."); //n>=0
    assert(a.length!1 >= a.length!0, "ormhr: The number of columns of 'a' " ~ 
           "must be greater than or equal to the number of its rows."); //m>=n
    assert(c.length!0 >= 0, "ormhr: The number of columns of 'c' must be " ~ 
           "greater than or equal to zero."); //n>=0
    assert(c.length!1 >= c.length!0, "ormhr: The number of columns of 'c' " ~ 
           "must be greater than or equal to the number of its rows."); //m>=n
    assert(tau.length >= 0, "ormhr: The input 'tau' must have length greater " ~ 
           "than or equal to zero."); //k>=0
    assert(a.length!0 >= tau.length, "ormhr: The number of columns of 'a' " ~ 
           "must be greater than or equal to the length of 'tau'."); //n>=k
    assert(work.length >= a.length!0, "ormhr: The length of 'work' must be " ~ 
           "greater than or equal to the number of rows of 'a'."); //lwork>=n
    assert(side == 'L' || side == 'R', "ormhr: 'side' must be" ~
           "one of 'L' or 'R'.");
    assert(trans == 'N' || trans == 'T', "ormhr: 'trans' must be" ~
           "one of 'N' or 'T'.");
}
do
{
    lapackint m = cast(lapackint) a.length!0;
    lapackint n = cast(lapackint) a.length!1;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldc = cast(lapackint) c._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;
    lapackint info = void;
    static if (!isComplex!T){
        lapack.ormhr_(side, trans, m, n, ilo, ihi, a.iterator, lda, tau.iterator, c.iterator, ldc, work.iterator, lwork, info);
    }
    else {
        lapack.unmhr_(side, trans, m, n, ilo, ihi, a.iterator, lda, tau.iterator, c.iterator, ldc, work.iterator, lwork, info);
    }
    ///if info == 0: successful exit.
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return cast(size_t)info;
}

unittest
{
    alias s = unmhr!cfloat;
    alias d = unmhr!cdouble;
    alias a = ormhr!double;
    alias b = ormhr!float;
}

size_t hseqr(T, complexT)(
    char job,
    char compz,
    Slice!(T*, 2, Canonical) h,
    Slice!(complexT*) w,
    Slice!(T*, 2, Canonical) z,
    Slice!(T*) work,
    lapackint* ilo,
    lapackint* ihi
)
    if ((isComplex!T && is(T == complexT)) || (!isComplex!T && is(T == realType!complexT)))
in
{
    assert(job == 'E' || job == 'S', "hseqr");
    assert(compz == 'N' || compz == 'I' || compz == 'V', "hseqr");
    assert(h.length!1 >= h.length!0, "hseqr");
    assert(h.length!1 >= 1, "hseqr");
    assert(compz != 'V' || compz != 'I' || (z.length!1 >= h.length!0 && z.length!1 >= 1), "hseqr");
    assert(compz != 'N' || z.length!1 >= 1);
    assert(work.length!0 >= 1, "hseqr");
    assert(work.length!0 >= h.length!0, "hseqr");
}
do
{
    lapackint n = cast(lapackint) h.length!0;
    lapackint ldh = cast(lapackint) h._stride.max(1);
    lapackint ldz = cast(lapackint) z._stride.max(1);
    lapackint lwork = cast(lapackint) work.length!0;
    lapackint info;
    static if(isComplex!T)
    {
        lapack.hseqr_(job,compz,n,ilo,ihi,h.iterator, ldh, w.iterator, z.iterator, ldz, work.iterator, lwork, info);
    }
    else
    {
    	auto wr = mininitRcslice!T(w.length);
    	auto wi = mininitRcslice!T(w.length);
    	lapack.hseqr_(job,compz,n,ilo,ihi,h.iterator, ldh, wr.lightScope.iterator, wi.lightScope.iterator, z.iterator, ldz, work.iterator, lwork, info);
    	w[] = wr[] + (1i * wi[]);
    }
    assert(info >= 0);
    return cast(size_t)info;
}

unittest
{
    alias f = hseqr!(float, cfloat);
    alias d = hseqr!(double, cdouble);
    alias s = hseqr!(cfloat, cfloat);
    alias c = hseqr!(cdouble, cdouble);
}

size_t trevc(T)(char side,
    char howmany,
    lapackint select,
    Slice!(T*, 2, Canonical) t,
    Slice!(T*, 2, Canonical) vl,
    Slice!(T*, 2, Canonical) vr,
    lapackint* m,
    Slice!(T*) work
)
do
{
    lapackint n = cast(lapackint)t.length!0;
    lapackint ldt = cast(lapackint) t._stride.max(1);
    lapackint ldvl = cast(lapackint) vl._stride.max(1);
    lapackint ldvr = cast(lapackint) vr._stride.max(1);
    lapackint mm = cast(lapackint) vr.length!1;
    //select should be lapack_logical
    lapackint info;
    static if(!isComplex!T){
        lapack.trevc_(side, howmany, &select, n, t.iterator, ldt, vl.iterator, ldvl, vr.iterator, ldvr, &mm, *m, work.iterator, info);
    }
    else {
        lapack.trevc_(side, howmany, &select, n, t.iterator, ldt, vl.iterator, ldvl, vr.iterator, ldvr, &mm, *m, work.iterator, null, info);
    }
    assert(info >= 0);
    return cast(size_t)info;
}

unittest
{
    alias f = trevc!float;
    alias d = trevc!double;
    alias s = trevc!cfloat;
    alias c = trevc!cdouble;
}

alias complexType(T : double) = cdouble;
alias complexType(T : float) = cfloat;
alias complexType(T : real) = creal;
alias complexType(T : isComplex!T) = T;

size_t gebal(T, realT)(char job,
    Slice!(T*, 2, Canonical) a,
    lapackint* ilo,
    lapackint* ihi,
    Slice!(realT*) scale
)
    if (!isComplex!T || (isComplex!T && is(realType!T == realT)))
{
    lapackint n = cast(lapackint) a.length!0;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint info = void;
    lapack.gebal_(job, n, a.iterator, lda, ilo, ihi, scale.iterator, info);
    assert(info >= 0);
    return cast(size_t)info;
}

unittest
{
    alias a = gebal!(double,double);
    alias b = gebal!(cdouble,double);
    alias c = gebal!(float,float);
    alias d = gebal!(cfloat,float);
}

size_t gebak(T, realT)(
    char job,
    char side,
    lapackint* ilo,
    lapackint* ihi,
    Slice!(realT*) scale,
    Slice!(T*, 2, Canonical) v
)
    if (!isComplex!T || (isComplex!T && is(realType!T == realT)))
{
    lapackint n = cast(lapackint) scale.length!0;
    lapackint m = cast(lapackint) v.length!1;//num evects
    lapackint ldv = cast(lapackint) v._stride.max(1);
    lapackint info = void;
    lapack.gebak_(job, side, n, ilo, ihi, scale.iterator, m, v.iterator, ldv, info);
    assert(info >= 0);
    return cast(size_t)info;
}

unittest
{
    alias a = gebak!(double,double);
    alias b = gebak!(cdouble,double);
    alias c = gebak!(float,float);
    alias d = gebak!(cfloat,float);
}

size_t geev(T, realT)(
    char jobvl,
    char jobvr,
    Slice!(T*, 2, Canonical) a,
    Slice!(T*) w,
    Slice!(T*, 2, Canonical) vl,
    Slice!(T*, 2, Canonical) vr,
    Slice!(T*) work,
    Slice!(realT*) rwork
)
    if (isComplex!T && is(realType!T == realT))
{
    lapackint n = cast(lapackint) a.length!0;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldvr = cast(lapackint) vr._stride.max(1);
    lapackint ldvl = cast(lapackint) vl._stride.max(1);
    lapackint info = void;
    lapackint lwork = cast(lapackint)work.length!0;
    lapack.geev_(jobvl, jobvr, n, a.iterator, lda, w.iterator, vl.iterator, ldvl, vr.iterator, ldvr, work.iterator, lwork, rwork.iterator, info);
    assert(info >= 0);
    return info;
}
size_t geev(T)(
    char jobvl,
    char jobvr,
    Slice!(T*, 2, Canonical) a,
    Slice!(T*) wr,
    Slice!(T*) wi,
    Slice!(T*, 2, Canonical) vl,
    Slice!(T*, 2, Canonical) vr,
    Slice!(T*) work
)
    if (!isComplex!T)
{
    lapackint n = cast(lapackint) a.length!0;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldvr = cast(lapackint) vr._stride.max(1);
    lapackint ldvl = cast(lapackint) vl._stride.max(1);
    lapackint info = void;
    lapackint lwork = cast(lapackint)work.length!0;
    lapack.geev_(jobvl, jobvr, n, a.iterator, lda, wr.iterator, wi.iterator, vl.iterator, ldvl, vr.iterator, ldvr, work.iterator, lwork, info);
    assert(info >= 0);
    return info;
}
