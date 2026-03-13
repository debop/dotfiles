---
name: kotlin-junit5-testing
description: Use when writing or reviewing Kotlin tests with JUnit5, Kluent assertions, MockK mocks, bluetape4k-junit5 utilities, multithreading testers, or coroutine job testers.
---

# Kotlin JUnit5 + Kluent + MockK 테스트 스킬

## Assertion 우선순위

**Kluent → JUnit5 순서**로 사용. Kluent assertion으로 표현 가능하면 JUnit5 사용 금지.

```kotlin
// ✅ Kluent 우선
result.shouldBeNull()
result.shouldNotBeNull()
result.shouldBeEmpty()
result.shouldBeEqualTo(expected)
result.shouldBeTrue()
result.shouldBeFalse()
list.shouldHaveSize(3)
list.shouldContain(item)
list.shouldNotContain(item)
list.shouldBeEmpty()
str.shouldContain("keyword")
str.shouldStartWith("prefix")

// ❌ Kluent로 가능한데 JUnit5 쓰는 것
assertEquals(expected, actual)   // → actual.shouldBeEqualTo(expected)
assertNull(result)                // → result.shouldBeNull()
assertTrue(result)                // → result.shouldBeTrue()

// ✅ JUnit5 fallback (Kluent에 없을 때만)
assertThrows<IllegalArgumentException> { service.call() }
assertDoesNotThrow { service.call() }
```

## MockK 기본 패턴

```kotlin
// Mock 생성
val repo = mockk<UserRepository>()
val emailSvc = mockk<EmailService>(relaxed = true) // 검증 불필요한 의존성

// Stubbing
every { repo.findById(1L) } returns User(id = 1L, name = "홍길동")
every { repo.findById(not(1L)) } throws EntityNotFoundException()

// Suspend 함수 stubbing
coEvery { repo.findSuspend(1L) } returns User(id = 1L, name = "홍길동")

// Capture
val slot = slot<User>()
every { repo.save(capture(slot)) } returns mockk()

// 검증
verify(exactly = 1) { repo.findById(1L) }
coVerify { emailSvc.send(any()) }
confirmVerified(repo)  // 불필요한 호출 방지
```

## bluetape4k-junit5 사용 패턴

### runSuspendIO / runTest

```kotlin
// 물리적 시간(delay, timeout)이 있을 때 → runTest (가상 시간)
@Test
fun `가상 시간 테스트`() = runTest {
    val result = service.fetchWithDelay()
    result.shouldBeEqualTo(expected)
}

// IO 작업이 있을 때 → runSuspendIO
@Test
fun `IO suspend 테스트`() = runSuspendIO {
    val result = repository.findById(1L)
    result.shouldNotBeNull()
}
```

### Awaitility (비동기 완료 대기)

```kotlin
// 일반 비동기 대기
await().atMost(5, SECONDS).untilAsserted {
    repo.findById(id).shouldNotBeNull()
}

// Coroutine suspend 함수 대기 → untilSuspending {} 사용
await().atMost(5, SECONDS).untilSuspending {
    service.getStatus() shouldBeEqualTo "DONE"
}
```

## 멀티스레딩 테스트

### MultithreadingTester

```kotlin
@Test
fun `동시 접근 안전성 검증`() {
    val counter = AtomicCounter()

    MultithreadingTester()
        .numThreads(16)
        .roundsPerThread(100)
        .add { counter.increment() }
        .run()

    counter.get().shouldBeEqualTo(1600)
}
```

### StructuredTaskScopeTester

```kotlin
@Test
fun `StructuredTaskScope 병렬 작업 검증`() {
    StructuredTaskScopeTester()
        .numTasks(32)
        .add { service.processItem(it) }
        .run()
        .shouldBeTrue()  // 모든 작업 성공 여부
}
```

## 코루틴 환경 테스트

### SuspendedJobTester

```kotlin
@Test
fun `코루틴 동시 실행 검증`() = runTest {
    val results = SuspendedJobTester()
        .numCoroutines(16)
        .roundsPerCoroutine(50)
        .add { service.suspendOperation() }
        .run()

    results.shouldBeTrue()
}
```

## 테스트 구조 원칙

```kotlin
@Test
fun `주문 생성 - 재고 충분할 때 성공`() {
    // Given
    val request = OrderRequest(productId = 1L, quantity = 2)
    every { stockRepo.getStock(1L) } returns 10

    // When
    val result = orderService.create(request)

    // Then
    result.shouldNotBeNull()
    result.status.shouldBeEqualTo(OrderStatus.CREATED)
    verify(exactly = 1) { stockRepo.getStock(1L) }
}
```

## 빠른 참조

| 상황 | 도구 |
|------|------|
| null 검사 | `shouldBeNull()` / `shouldNotBeNull()` |
| 동등 비교 | `shouldBeEqualTo(expected)` |
| Boolean | `shouldBeTrue()` / `shouldBeFalse()` |
| 컬렉션 비어있음 | `shouldBeEmpty()` |
| suspend mock | `coEvery { }` / `coVerify { }` |
| 물리적 시간 없음 | `runTest` (가상 시간) |
| IO suspend | `runSuspendIO` |
| 비동기 완료 대기 | `await().untilAsserted {}` |
| coroutine 완료 대기 | `await().untilSuspending {}` |
| 멀티스레드 안전성 | `MultithreadingTester` |
| 병렬 Task 검증 | `StructuredTaskScopeTester` |
| 코루틴 동시 실행 | `SuspendedJobTester` |

## 흔한 실수

```kotlin
// ❌ relaxed mock에 verify
val svc = mockk<EmailService>(relaxed = true)
verify { svc.send(any()) }  // relaxed는 검증 불필요 의존성에만

// ❌ suspend 함수에 every 사용
every { repo.findSuspend(1L) } returns user  // → coEvery 사용

// ❌ 물리적 딜레이 없는데 runSuspendIO 대신 runBlocking
runBlocking { repo.findById(1L) }  // → runSuspendIO { } 사용

// ❌ coroutine 대기에 일반 untilAsserted
await().untilAsserted { suspendFun() }  // → untilSuspending { } 사용

// ❌ confirmVerified 누락
verify { repo.findById(1L) }
// confirmVerified(repo) 빠지면 예상치 못한 호출 검증 안됨
```
