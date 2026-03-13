---
name: bluetape4k-patterns
description: Use when writing or reviewing Kotlin code in bluetape4k projects - covers argument validation, logging, value objects, magic literals, AtomicFU, DSL builders, Spring Boot auto-config, exception handling, and module setup conventions.
---

# bluetape4k 구현 패턴 스킬

## 인자 검사 (Argument Validation)

bluetape4k 확장 함수 사용. `require()` / `checkNotNull()` 사용 금지.

### require vs check 구분

| 함수 | 예외 | 용도 |
|------|------|------|
| `require*()` | `IllegalArgumentException` | **호출자** 인자 검증 |
| `check()` | `IllegalStateException` | **내부** 상태/연산 결과 검증 |

```kotlin
// ✅ 인자 검증 - bluetape4k 확장 함수
name.requireNotBlank("name")
age.requirePositiveNumber("age")
id.requireNotNull("id")
list.requireNotEmpty("list")
value.requireInRange(1..100, "value")

// ✅ 내부 상태/연산 결과 - stdlib check() 그대로 사용
private fun setRedisBulk(map: Map<String, V>) {
    val status = commands.mset(redisMap)
    check(status == "OK") { "Redis MSET failed: $status" }  // 내부 연산 결과
}

// ❌ 인자 검증에 stdlib 사용 금지
require(name.isNotBlank()) { "name must not be blank" }
checkNotNull(id) { "id must not be null" }
requireNotNull(id) { "id must not be null" }

// ❌ 내부 상태 검증에 require 오용
require(applied == true) { "Redis MSETEX failed" }  // → check() 써야 함
```

`init {}` 블록에서도 동일하게 적용:

```kotlin
data class NearCacheConfig(val cacheName: String, val maxSize: Long) {
    init {
        cacheName.requireNotBlank("cacheName")
        maxSize.requirePositiveNumber("maxSize")
    }
}
```

## 로깅 (Logging)

```kotlin
// ✅ 일반 환경 - KLogging()
class UserService {
    companion object : KLogging()

    fun findUser(id: Long): User {
        log.debug { "Finding user id=$id" }         // lazy - DEBUG 꺼지면 미평가
        log.warn(e) { "Failed to find user $id" }   // 예외 포함 로깅
        return repo.findById(id)
    }
}

// ✅ Coroutines 환경 - KLoggingChannel()
class AsyncUserService {
    companion object : KLoggingChannel()

    suspend fun findUser(id: Long): User {
        log.debug { "Finding user id=$id" }
        return repo.findById(id)
    }
}

// ❌ 사용하지 말 것
private val logger = LoggerFactory.getLogger(UserService::class.java)
private val log = logger<UserService>()
```

## Companion Object 패턴

```kotlin
class LettuceNearCache<V : Any>(
    private val redisClient: RedisClient,
    private val config: NearCacheConfig,
) : AutoCloseable {

    companion object : KLogging() {
        // ✅ factory invoke() - LettuceNearCache(...) 로 호출 가능
        operator fun invoke(
            redisClient: RedisClient,
            config: NearCacheConfig = NearCacheConfig(),
        ): LettuceNearCache<String> =
            LettuceNearCache(redisClient, StringCodec.UTF8, config)
    }
}
```

- `companion object : KLogging()` — 로깅 + 팩토리 메서드를 한 곳에
- `operator fun invoke(...)` — `LettuceNearCache(client)` 처럼 생성자처럼 호출
- `@JvmStatic` 불필요 — Kotlin companion 의 operator fun으로 충분

## AtomicFU (스레드 안전 상태)

```kotlin
import kotlinx.atomicfu.atomic

class LettuceNearCache<V : Any>(...) : AutoCloseable {
    private val closed = atomic(false)
    val isClosed by closed          // 읽기 전용 위임

    override fun close() {
        if (closed.compareAndSet(expect = false, update = true)) {
            // 한 번만 실행
            runCatching { connection.close() }
            log.debug { "Cache closed" }
        }
    }
}
```

- `atomic(false)` — `AtomicBoolean` 대신 사용
- `compareAndSet` — 중복 close 방지 패턴
- `val isClosed by closed` — getter 위임으로 읽기 전용 노출

## 예외 처리 패턴

### 우아한 실패 (Graceful Degradation)

```kotlin
// ✅ runCatching + onFailure
runCatching { trackingListener.start() }
    .onFailure { e ->
        log.warn(e) { "CLIENT TRACKING 시작 실패, invalidation 없이 동작" }
    }
```

### close() 독립적 래핑

```kotlin
// ✅ 각 리소스 독립 처리 - 하나 실패해도 나머지 정리
override fun close() {
    if (closed.compareAndSet(false, true)) {
        runCatching { trackingListener.close() }
        runCatching { connection.close() }
        runCatching { frontCache.close() }
    }
}

// ❌ try-finally 체인 - 중간 실패 시 이후 리소스 누수 가능
```

## DSL Builder 패턴

```kotlin
// ✅ inline - Kotlin 2.0+ builder inference 자동화 (@BuilderInference 불필요)
inline fun <K : Any, V : Any> nearCacheConfig(
    block: NearCacheConfigBuilder<K, V>.() -> Unit,
): NearCacheConfig<K, V> =
    NearCacheConfigBuilder<K, V>().apply(block).build()

class NearCacheConfigBuilder<K : Any, V : Any> {
    var cacheName: String = "lettuce-near-cache"
    var maxLocalSize: Long = 10_000
    var frontExpireAfterWrite: Duration = Duration.ofMinutes(30)

    fun build(): NearCacheConfig<K, V> = NearCacheConfig(
        cacheName = cacheName.requireNotBlank("cacheName"),
        maxLocalSize = maxLocalSize.requirePositiveNumber("maxLocalSize"),
        frontExpireAfterWrite = frontExpireAfterWrite,
    )
}

// 사용 - 타입 명시 불필요
val config = nearCacheConfig<String, String> {
    cacheName = "my-cache"
    maxLocalSize = 5_000
}
```

## Inline 유틸리티 함수

```kotlin
// ✅ 핫패스 유틸에 @Suppress 명시
@Suppress("NOTHING_TO_INLINE")
inline fun redisKey(key: String): String = "$cacheName:$key"

// @Suppress("OVERRIDE_DEPRECATION") - 상위 클래스 deprecated 메서드 오버라이드
@Suppress("OVERRIDE_DEPRECATION")
override fun getModulePrefix(): String = "exposed"
```

## Value Object

```kotlin
// ✅ Serializable + serialVersionUID 필수
data class UserId(val value: Long) : Serializable {
    init {
        value.requirePositiveNumber("UserId.value")
    }

    companion object : KLogging() {
        private const val serialVersionUID = 1L
    }
}

// ❌ Serializable 누락
data class UserId(val value: Long)
```

## Magic String / Magic Number 제거

```kotlin
// ❌ Magic literal
repo.findByType("ADMIN")
query.timeout(30_000)

// ✅ const 로 분리
companion object {
    const val DEFAULT_TIMEOUT_MS = 30_000L
}

// ✅ Kotlin reflection으로 프로퍼티명 참조 (오타 방지)
val columnName = User::name.name      // "name"
val fieldRef   = User::createdAt.name // "createdAt"

// ✅ Enum / sealed class 활용
enum class UserRole { ADMIN, USER, GUEST }
sealed class CacheRegion(val key: String) {
    object User    : CacheRegion("user")
    object Product : CacheRegion("product")
}
```

## Spring Boot Auto-Configuration

```kotlin
// ✅ @ConditionalOnClass 반드시 클래스 레벨에 선언
@AutoConfiguration(after = [LettuceNearCacheAutoConfiguration::class])
@ConditionalOnClass(LettuceNearCacheRegionFactory::class, MeterRegistry::class)
@ConditionalOnBean(EntityManagerFactory::class, MeterRegistry::class)
@ConditionalOnProperty(
    prefix = "bluetape4k.cache.lettuce-near.metrics",
    name = ["enabled"],
    havingValue = "true",
    matchIfMissing = true,
)
@EnableConfigurationProperties(LettuceNearCacheSpringProperties::class)
class LettuceNearCacheMetricsAutoConfiguration {

    @Bean
    fun lettuceNearCacheMetricsBinder(
        entityManagerFactory: EntityManagerFactory,
        meterRegistry: MeterRegistry,
    ): LettuceNearCacheMetricsBinder =
        LettuceNearCacheMetricsBinder(entityManagerFactory, meterRegistry)
}
```

- `@ConditionalOnClass` — 클래스 레벨 필수 (메서드 레벨만으론 `NoClassDefFoundError` 가능)
- `@AutoConfiguration(after = [...])` — 의존 관계 명시
- `@Bean` 메서드는 생성자 주입 (필드 주입 금지)

## @ConfigurationProperties

```kotlin
@ConfigurationProperties(prefix = "bluetape4k.cache.lettuce-near")
data class LettuceNearCacheSpringProperties(
    val enabled: Boolean = true,
    val redisUri: String = "redis://localhost:6379",
    val local: LocalProperties = LocalProperties(),
    val redisTtl: RedisTtlProperties = RedisTtlProperties(),
) {
    data class LocalProperties(
        val maxSize: Long = 10_000,
        val expireAfterWrite: Duration = Duration.ofMinutes(30),
    )

    data class RedisTtlProperties(
        val default: Duration = Duration.ofSeconds(120),
        // 점(.) 포함 키는 대괄호 표기법
        // redis-ttl.regions[io.example.Product]=300s
        val regions: Map<String, Duration> = emptyMap(),
    )
}
```

- 모든 프로퍼티에 기본값 (required 없음)
- camelCase → YAML kebab-case 자동 매핑
- 중첩 data class로 계층 구조

## 새 모듈 설정

```
{module}/
├── build.gradle.kts
├── README.md                              # 필수
└── src/
    ├── main/kotlin/io/bluetape4k/...
    └── test/
        ├── kotlin/io/bluetape4k/...
        └── resources/
            ├── junit-platform.properties  # 기존 모듈에서 복사
            └── logback-test.xml           # 기존 모듈에서 복사
```

> 실제 파일 내용은 `bluetape4k-projects`의 기존 모듈에서 복사. `settings.gradle.kts`는 수정 불필요 (`includeModules()` 자동 감지).

## README.md 최신화

모든 작업 완료 후 README.md 업데이트 필수.

```markdown
# {module-name}

## 개요
이 모듈이 하는 일 1~2줄.

## 주요 기능
- 기능 A

## 사용 예제
\`\`\`kotlin
// 핵심 사용 패턴
\`\`\`

## 의존성
\`\`\`kotlin
testImplementation(project(":module-name"))
\`\`\`
```

## 테스트 작성 원칙

```kotlin
// @BeforeEach setup - runBlocking 허용 (테스트 설정만)
@BeforeEach
fun setUp(): Unit = runBlocking {
    SchemaUtils.createMissingTablesAndColumns(Users)
    Users.deleteAll()
}

// 테스트 본문 - runTest (가상 시간)
@Test
fun `정상 케이스`() = runTest {
    val result = service.findById(1L)
    result.shouldNotBeNull()
    result.name.shouldBeEqualTo("Alice")
}

// Edge case 필수 커버
@Test
fun `빈 문자열 입력 시 IllegalArgumentException 발생`() {
    assertThrows<IllegalArgumentException> { service.process("") }
}

@Test
fun `null 입력 시 IllegalArgumentException 발생`() {
    assertThrows<IllegalArgumentException> { service.process(null) }
}

@Test fun `경계값 - 최솟값`() { ... }
@Test fun `경계값 초과 시 예외 발생`() { ... }
```

트랜잭션 래핑 헬퍼 (가독성):

```kotlin
private suspend fun <T> inTx(block: suspend () -> T): T =
    suspendTransaction { block() }
```

## Testcontainers 싱글턴 패턴

인프라(Redis, Kafka 등)가 필요한 테스트는 `object XxxServers` 싱글턴으로 모든 테스트가 컨테이너를 공유.

```kotlin
// ✅ 모듈 전역 싱글턴 object
object RedisServers {
    /** 첫 접근 시 컨테이너 시작, ShutdownQueue에 종료 훅 자동 등록 */
    val redisServer: RedisServer by lazy { RedisServer.Launcher.redis }

    val redisClient by lazy {
        RedisServer.Launcher.LettuceLib.getRedisClient(redisServer.url)
    }

    @JvmStatic
    val faker = Fakers.faker

    @JvmStatic
    fun randomName(): String = "$LibraryName:${Base58.randomString(8)}"

    @JvmStatic
    fun randomString(size: Int = 2048): String = Fakers.fixedString(size)
}

// 테스트에서 사용
class MyRedisTest {
    private val redisServer = RedisServers.redisServer   // 공유 컨테이너

    @Test
    fun `redis test`() {
        // redisServer.host, redisServer.port 사용
    }
}
```

- `RedisServer.Launcher.redis` — bluetape4k-testcontainers의 미리 구성된 싱글턴
- `ShutdownQueue.register(this)` — Launcher 내부에서 자동 처리
- `@Testcontainers` 어노테이션 불필요

## Abstract 테스트 기반 클래스 패턴

공통 설정/픽스처를 `AbstractXxxTest`에 집중.

```kotlin
// ✅ 공통 설정을 abstract 클래스에
abstract class AbstractCacheTest {
    companion object : KLogging() {
        @JvmStatic
        val faker: Faker = Fakers.faker          // 테스트 데이터 생성

        @JvmStatic
        val redisServer = RedisServers.redisServer
    }

    // JPA 테스트용 헬퍼
    protected fun flushAndClear() {
        tem.flush()
        tem.clear()
    }
}

// ✅ lateinit 재초기화 방지
@BeforeEach
fun setUp(): Unit = runBlocking {
    if (!::database.isInitialized) {     // 비용 큰 리소스 1회만 초기화
        database = Database.connect(url, driver)
    }
    // 데이터 초기화는 매번
    transaction { TestTable.deleteAll() }
}
```

## 테스트 픽스처 유틸리티 (Fakers)

```kotlin
import io.bluetape4k.junit5.faker.Fakers

// ✅ 기본 faker 인스턴스 (companion object에)
@JvmStatic val faker = Fakers.faker

// ✅ 고정 크기 문자열 (대용량 데이터 테스트용)
val bigData = Fakers.fixedString(2048)

// ✅ 랜덤 문자열
val name    = faker.name().fullName()
val email   = faker.internet().emailAddress()
val address = faker.address().fullAddress()
```

## Flow 스트리밍 Repository 패턴

```kotlin
// ✅ 대용량 결과는 Flow<T> 반환 (Flux<T> 대신)
interface UserRepository {
    suspend fun findAll(): Flow<User>          // 스트리밍
    suspend fun findById(id: Long): User?     // 단건
    suspend fun count(): Long
}

// 구현 - suspendTransaction 내에서 emit
override fun findAll(): Flow<User> = flow {
    suspendTransaction(database) {
        Users.selectAll().forEach { row ->
            emit(row.toUser())               // 지연 방출
        }
    }
}

// 사용
userRepository.findAll()
    .filter { it.active }
    .take(100)
    .toList()
```

## 타입 안전 매퍼 함수 패턴

리플렉션 대신 명시적 함수 파라미터로 타입 안전성 보장.

```kotlin
// ✅ 함수 파라미터로 매핑 - 리플렉션 없음
class UserRepository(
    private val table: IdTable<Long>,
    private val toDomain: (ResultRow) -> User,           // DB → 도메인
    private val toColumns: (User) -> Map<Column<*>, Any?>, // 도메인 → DB
) {
    suspend fun findAll(): Flow<User> = flow {
        suspendTransaction { table.selectAll().forEach { emit(toDomain(it)) } }
    }
}

// 생성 - 람다로 매핑 정의
val userRepo = UserRepository(
    table = Users,
    toDomain = { row -> User(id = row[Users.id].value, name = row[Users.name]) },
    toColumns = { user -> mapOf(Users.name to user.name) },
)
```

## IntelliJ IDE 진단 (코드 작성/리뷰 후)

`mcp__intellij-index__ide_diagnostics` 도구로 파일 단위 IDE 검사를 실행한다.
IDE가 포커스를 얻어야 재검사하므로, 편집 후 `ide_sync_files`로 인덱스를 갱신한다.

```
# 단일 파일 검사
mcp__intellij-index__ide_diagnostics(
    file = "infra/cache-lettuce-near/src/main/kotlin/.../Foo.kt",
    project_path = "/Users/debop/work/bluetape4k/bluetape4k-experimental"
)

# 여러 파일 병렬 검사 → 한 메시지에 여러 tool call 동시 실행

# 인덱스 강제 갱신 (편집 직후 stale 결과가 나올 때)
mcp__intellij-index__ide_sync_files(
    project_path = "/Users/debop/work/bluetape4k/bluetape4k-experimental"
)
```

### severity별 처리 기준

| severity | 처리 |
|----------|------|
| ERROR | 반드시 수정 |
| WARNING - 미사용 import | 제거 |
| WARNING - `private val` 생성자 파라미터 미사용 | `val` 제거 (초기화에만 쓰임) |
| WARNING - deprecated API | 대안으로 교체 |
| WEAK_WARNING - naming `_prefix` | 언더스코어 제거 |
| WEAK_WARNING - setter 대신 property | `setFoo(x)` → `foo = x` |
| WEAK_WARNING - boolean literal 인수 | named argument 적용 |
| WEAK_WARNING - 중복 코드 조각 | **건드리지 않음** (의도적 분리) |

### 자주 나오는 패턴과 수정

```kotlin
// WARNING: 생성자 전용 파라미터 private val 불필요
class Foo(
    redisClient: RedisClient,        // ✅ val 없음 - 초기화에만 사용
    private val config: Config,      // ✅ val 유지 - 메서드에서 사용
)

// WEAK_WARNING: boolean literal without param name
closed.compareAndSet(expect = false, update = true)  // ✅

// WEAK_WARNING: setter method 대신 property
options = ClientOptions.builder().build()  // ✅ (setOptions(...) 대신)

// WEAK_WARNING: when subject 삽입
when (idType) {                    // ✅ when(idType) 사용
    Long::class.java -> ...
    else -> ...
}
// ❌ when { idType == Long::class.java -> ... }

// WARNING: @BuilderInference deprecated (Kotlin 2.0+)
inline fun <K, V> nearCacheConfig(block: Builder<K,V>.() -> Unit) // ✅ 어노테이션 없이
```

## 빠른 체크리스트

| 항목 | 확인 |
|------|------|
| 인자 검사: `requireNotBlank/Null/PositiveNumber` | ✓ |
| 로깅: 일반→`KLogging()`, 코루틴→`KLoggingChannel()` | ✓ |
| log 호출: `log.debug { }` (lazy), `log.warn(e) { }` (예외) | ✓ |
| 스레드 안전 상태: `atomic()` from AtomicFU | ✓ |
| Companion object에 factory `invoke()` 고려 | ✓ |
| 리소스 close: 각각 `runCatching` 독립 래핑 | ✓ |
| Value object: `Serializable` + `serialVersionUID` | ✓ |
| Magic literal 제거: `const` 또는 reflection | ✓ |
| `@ConditionalOnClass` 클래스 레벨 선언 | ✓ |
| Testcontainers: `object XxxServers` 싱글턴 + `by lazy { Server.Launcher.xxx }` | ✓ |
| Abstract 테스트 클래스: `@JvmStatic val faker = Fakers.faker` | ✓ |
| `::property.isInitialized` 로 비용 큰 리소스 1회 초기화 | ✓ |
| 대용량 결과: `Flow<T>` 반환 (Flux/List 대신) | ✓ |
| `src/test/resources`: `junit-platform.properties`, `logback-test.xml` | ✓ |
| `README.md` 업데이트 | ✓ |
| 테스트 작성 (Edge case 포함) | ✓ |
| IntelliJ IDE 진단: `ide_diagnostics` 실행 후 ERROR/WARNING 수정 | ✓ |
