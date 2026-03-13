---
name: kotest
description: Kotlin 테스트 작성 - Kotest, MockK, Spring Boot Test 패턴
tags: [kotlin, testing, kotest, mockk, spring]
---

# Kotest + MockK 테스트 스킬

## 테스트 스타일 선택

```kotlin
// BehaviorSpec - BDD 스타일 (Given/When/Then)
class OrderServiceSpec : BehaviorSpec({
    given("주문 생성 요청") {
        val order = OrderRequest(productId = 1L, quantity = 2)
        `when`("재고가 충분할 때") {
            then("주문이 생성된다") {
                // ...
            }
        }
    }
})

// DescribeSpec - RSpec 스타일
class UserServiceSpec : DescribeSpec({
    describe("findById") {
        context("존재하는 유저 ID") {
            it("유저를 반환한다") { }
        }
        context("존재하지 않는 유저 ID") {
            it("예외를 던진다") { }
        }
    }
})

// StringSpec - 간단한 단위 테스트
class CalculatorSpec : StringSpec({
    "1 + 1 은 2다" {
        (1 + 1) shouldBe 2
    }
})
```

## MockK 기본 패턴

```kotlin
// Mock 생성
val userRepository = mockk<UserRepository>()
val emailService = mockk<EmailService>(relaxed = true) // 모든 함수 기본 반환

// stubbing
every { userRepository.findById(1L) } returns User(id = 1L, name = "홍길동")
every { userRepository.findById(not(1L)) } throws EntityNotFoundException()

// suspend 함수
coEvery { userRepository.findByIdSuspend(1L) } returns User(id = 1L, name = "홍길동")

// 검증
verify(exactly = 1) { userRepository.findById(1L) }
coVerify { emailService.send(any()) }
confirmVerified(userRepository)
```

## Kotest Assertions

```kotlin
// 기본
result shouldBe expected
result shouldNotBe null
result.shouldBeInstanceOf<User>()

// 컬렉션
list shouldHaveSize 3
list shouldContain item
list.shouldBeEmpty()
list shouldContainAll listOf(1, 2, 3)

// 예외
shouldThrow<IllegalArgumentException> {
    service.doSomething(invalidInput)
}.message shouldContain "invalid"

// 비동기
eventually(5.seconds) {
    repository.findById(id) shouldNotBe null
}
```

## Spring Boot Test 패턴

```kotlin
@SpringBootTest
@ActiveProfiles("test")
class UserControllerIntegrationTest(
    private val mockMvc: MockMvc,
    private val userRepository: UserRepository,
) : DescribeSpec({

    afterEach { userRepository.deleteAll() }

    describe("GET /api/users/{id}") {
        context("존재하는 유저") {
            it("200 OK와 유저 정보를 반환한다") {
                val user = userRepository.save(User(name = "테스트"))
                mockMvc.get("/api/users/${user.id}")
                    .andExpect { status { isOk() } }
                    .andExpect { jsonPath("$.name") { value("테스트") } }
            }
        }
    }
})
```

## Kotest + Coroutines

```kotlin
class FlowServiceSpec : FunSpec({
    test("Flow 이벤트 수집") {
        val service = FlowService()
        val results = service.eventFlow()
            .take(3)
            .toList()
        results shouldHaveSize 3
    }

    test("StateFlow 값 확인") {
        val viewModel = MyViewModel()
        viewModel.uiState.value shouldBe UiState.Loading
        viewModel.load()
        viewModel.uiState.value.shouldBeInstanceOf<UiState.Success>()
    }
})
```

## build.gradle.kts 설정

```kotlin
dependencies {
    testImplementation("io.kotest:kotest-runner-junit5:5.9.1")
    testImplementation("io.kotest:kotest-assertions-core:5.9.1")
    testImplementation("io.kotest:kotest-extensions-spring:1.3.0")
    testImplementation("io.mockk:mockk:1.13.12")
    testImplementation("io.mockk:mockk-agent:1.13.12")
}

tasks.withType<Test> {
    useJUnitPlatform()
}
```

## 테스트 작성 원칙

1. **Given/When/Then** 구조 명확히 유지
2. **MockK relaxed** 는 검증 불필요한 의존성에만 사용
3. **confirmVerified** 로 불필요한 호출 방지
4. **@Transactional** 은 통합 테스트에서 롤백 용도로만
5. 픽스처는 **팩토리 함수**로 분리 (`fun createUser(...) = User(...)`)
