import React, { useState } from 'react';
import { CreditCard, TrendingUp, History, User, DollarSign, ArrowUpRight, CheckCircle, Upload, FileText, Shield, AlertCircle, Check, X, Eye, Copy, Wallet } from 'lucide-react';

export default function DepositBrokerSystem() {
  const WALLET_ADDRESS = 'TW9sELgwj7MRUEXa6Frr2ocaPt3y8mgjWB';
  const [balance, setBalance] = useState(5000);
  const [activeTab, setActiveTab] = useState('dashboard');
  const [depositAmount, setDepositAmount] = useState('');
  const [isAdmin, setIsAdmin] = useState(false);
  const [showSuccess, setShowSuccess] = useState(false);
  const [successMessage, setSuccessMessage] = useState('');
  const [txHash, setTxHash] = useState('');
  const [depositProof, setDepositProof] = useState(null);
  
  const [userDocs, setUserDocs] = useState({
    idCard: { file: null, status: 'pending', fileName: '' },
    addressProof: { file: null, status: 'pending', fileName: '' },
    selfie: { file: null, status: 'pending', fileName: '' }
  });

  const [pendingDeposits, setPendingDeposits] = useState([
    {
      id: 1,
      userId: 1,
      userName: 'أحمد محمد',
      amount: 500,
      txHash: '0x1a2b3c4d5e6f7890abcdef...',
      proof: 'deposit_proof_1.jpg',
      date: '2026-01-11',
      status: 'pending',
      network: 'TRC20'
    }
  ]);

  const [allUsers, setAllUsers] = useState([
    {
      id: 1,
      name: 'أحمد محمد',
      email: 'ahmed@example.com',
      docs: {
        idCard: { fileName: 'id_card.jpg', status: 'pending', uploadDate: '2026-01-10' },
        addressProof: { fileName: 'address.pdf', status: 'pending', uploadDate: '2026-01-10' },
        selfie: { fileName: 'selfie.jpg', status: 'pending', uploadDate: '2026-01-10' }
      },
      accountStatus: 'pending'
    }
  ]);

  const [transactions, setTransactions] = useState([
    { id: 1, type: 'deposit', amount: 1000, date: '2026-01-10', method: 'USDT TRC20', txHash: '0xabc...' },
    { id: 2, type: 'deposit', amount: 2000, date: '2026-01-08', method: 'USDT TRC20', txHash: '0xdef...' },
  ]);

  const copyToClipboard = (text) => {
    navigator.clipboard.writeText(text);
    showSuccessMsg('تم نسخ عنوان المحفظة! ✓');
  };

  const handleFileUpload = (docType, e) => {
    const file = e.target.files[0];
    if (file) {
      setUserDocs({...userDocs, [docType]: { file: file, status: 'pending', fileName: file.name }});
      showSuccessMsg('تم رفع الملف بنجاح!');
    }
  };

  const handleDepositProofUpload = (e) => {
    const file = e.target.files[0];
    if (file) {
      setDepositProof(file);
      showSuccessMsg('تم رفع إثبات التحويل!');
    }
  };

  const submitDeposit = () => {
    if (!depositAmount || !txHash || !depositProof) {
      showSuccessMsg('⚠️ يرجى ملء جميع الحقول');
      return;
    }

    const newDeposit = {
      id: pendingDeposits.length + 1,
      userId: 0,
      userName: 'مستخدم تجريبي',
      amount: parseFloat(depositAmount),
      txHash: txHash,
      proof: depositProof.name,
      date: new Date().toISOString().split('T')[0],
      status: 'pending',
      network: 'TRC20'
    };

    setPendingDeposits([newDeposit, ...pendingDeposits]);
    setDepositAmount('');
    setTxHash('');
    setDepositProof(null);
    showSuccessMsg('تم إرسال طلب الإيداع بنجاح! ✓');
  };

  const approveDeposit = (depositId) => {
    const deposit = pendingDeposits.find(d => d.id === depositId);
    if (deposit) {
      setPendingDeposits(pendingDeposits.map(d => d.id === depositId ? { ...d, status: 'approved' } : d));
      const newTx = {
        id: transactions.length + 1,
        type: 'deposit',
        amount: deposit.amount,
        date: deposit.date,
        method: 'USDT TRC20',
        txHash: deposit.txHash
      };
      setTransactions([newTx, ...transactions]);
      setBalance(balance + deposit.amount);
      showSuccessMsg(`تمت الموافقة! تم إضافة $${deposit.amount}`);
    }
  };

  const rejectDeposit = (depositId) => {
    setPendingDeposits(pendingDeposits.map(d => d.id === depositId ? { ...d, status: 'rejected' } : d));
    showSuccessMsg('تم رفض طلب الإيداع');
  };

  const approveDocument = (userId, docType) => {
    setAllUsers(allUsers.map(user => {
      if (user.id === userId) {
        const updatedDocs = { ...user.docs };
        updatedDocs[docType].status = 'approved';
        const allApproved = Object.values(updatedDocs).every(doc => doc.status === 'approved');
        return { ...user, docs: updatedDocs, accountStatus: allApproved ? 'verified' : 'pending' };
      }
      return user;
    }));
    showSuccessMsg('تم الموافقة على الوثيقة!');
  };

  const rejectDocument = (userId, docType) => {
    setAllUsers(allUsers.map(user => {
      if (user.id === userId) {
        const updatedDocs = { ...user.docs };
        updatedDocs[docType].status = 'rejected';
        return { ...user, docs: updatedDocs, accountStatus: 'rejected' };
      }
      return user;
    }));
    showSuccessMsg('تم رفض الوثيقة');
  };

  const showSuccessMsg = (msg) => {
    setSuccessMessage(msg);
    setShowSuccess(true);
    setTimeout(() => setShowSuccess(false), 3000);
  };

  const getStatusBadge = (status) => {
    const config = {
      pending: { bg: 'bg-yellow-100 text-yellow-800', label: 'قيد المراجعة' },
      approved: { bg: 'bg-green-100 text-green-800', label: 'موافق' },
      rejected: { bg: 'bg-red-100 text-red-800', label: 'مرفوض' },
      verified: { bg: 'bg-blue-100 text-blue-800', label: 'محقق' }
    };
    return <span className={`px-3 py-1 rounded-full text-sm font-medium ${config[status].bg}`}>{config[status].label}</span>;
  };

  const TabButton = ({ id, icon: Icon, label }) => (
    <button onClick={() => setActiveTab(id)} className={`flex items-center gap-2 px-6 py-3 rounded-lg transition ${activeTab === id ? 'bg-blue-600 text-white shadow-lg' : 'bg-white text-gray-600 hover:bg-gray-50'}`}>
      <Icon size={20} />
      <span className="font-medium">{label}</span>
    </button>
  );

  const verificationStatus = Object.values(userDocs).every(doc => doc.status === 'approved');

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 p-6" dir="rtl">
      <div className="max-w-6xl mx-auto">
        <div className="bg-white rounded-2xl shadow-xl p-6 mb-6">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-4">
              <div className="bg-blue-600 p-3 rounded-xl">
                <TrendingUp className="text-white" size={32} />
              </div>
              <div>
                <h1 className="text-3xl font-bold text-gray-800">بروكر الإيداع المالي</h1>
                <p className="text-gray-600">إيداع عبر USDT TRC20</p>
              </div>
            </div>
            <div className="text-left">
              <p className="text-sm text-gray-600">الرصيد الكلي</p>
              <p className="text-3xl font-bold text-blue-600">${balance.toLocaleString()}</p>
            </div>
          </div>
          
          <div className="flex items-center gap-3 pt-4 border-t">
            <button onClick={() => { setIsAdmin(!isAdmin); setActiveTab(isAdmin ? 'dashboard' : 'admin-deposits'); }} className={`px-4 py-2 rounded-lg font-medium transition ${isAdmin ? 'bg-purple-600 text-white' : 'bg-gray-200 text-gray-700'}`}>
              {isAdmin ? '👑 وضع المسؤول' : '👤 وضع المستخدم'}
            </button>
            <span className="text-sm text-gray-600">(انقر للتبديل)</span>
          </div>
        </div>

        {showSuccess && (
          <div className="bg-green-100 border-r-4 border-green-500 text-green-700 p-4 mb-6 rounded-lg flex items-center gap-3">
            <CheckCircle size={24} />
            <p className="font-medium">{successMessage}</p>
          </div>
        )}

        {!isAdmin ? (
          <div className="flex gap-4 mb-6 flex-wrap">
            <TabButton id="dashboard" icon={TrendingUp} label="لوحة التحكم" />
            <TabButton id="deposit" icon={Wallet} label="إيداع USDT" />
            <TabButton id="verification" icon={Shield} label="التحقق" />
            <TabButton id="history" icon={History} label="السجل" />
          </div>
        ) : (
          <div className="flex gap-4 mb-6 flex-wrap">
            <TabButton id="admin-deposits" icon={Wallet} label="طلبات الإيداع" />
            <TabButton id="admin-verify" icon={Shield} label="مراجعة الوثائق" />
            <TabButton id="admin-users" icon={User} label="المستخدمين" />
          </div>
        )}

        <div className="bg-white rounded-2xl shadow-xl p-6">
          {!isAdmin ? (
            <>
              {activeTab === 'dashboard' && (
                <div>
                  <h2 className="text-2xl font-bold mb-6">نظرة عامة</h2>
                  {!verificationStatus && (
                    <div className="mb-6 p-4 bg-yellow-50 border-r-4 border-yellow-500 rounded-lg flex items-start gap-3">
                      <AlertCircle className="text-yellow-600 mt-1" size={24} />
                      <div>
                        <p className="font-bold text-yellow-800">حسابك غير محقق</p>
                        <button onClick={() => setActiveTab('verification')} className="mt-2 bg-yellow-600 text-white px-4 py-2 rounded-lg">
                          التحقق الآن
                        </button>
                      </div>
                    </div>
                  )}
                  <div className="grid md:grid-cols-3 gap-6">
                    <div className="bg-gradient-to-br from-green-500 to-green-600 rounded-xl p-6 text-white">
                      <DollarSign size={32} className="mb-4" />
                      <p className="text-green-100 text-sm">إجمالي الإيداعات</p>
                      <p className="text-3xl font-bold">${transactions.reduce((s, t) => s + t.amount, 0).toLocaleString()}</p>
                    </div>
                    <div className="bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl p-6 text-white">
                      <Wallet size={32} className="mb-4" />
                      <p className="text-blue-100 text-sm">الرصيد الحالي</p>
                      <p className="text-3xl font-bold">${balance.toLocaleString()}</p>
                    </div>
                    <div className="bg-gradient-to-br from-purple-500 to-purple-600 rounded-xl p-6 text-white">
                      <History size={32} className="mb-4" />
                      <p className="text-purple-100 text-sm">عدد المعاملات</p>
                      <p className="text-3xl font-bold">{transactions.length}</p>
                    </div>
                  </div>
                </div>
              )}

              {activeTab === 'deposit' && (
                <div>
                  <h2 className="text-2xl font-bold mb-6">إيداع USDT (TRC20)</h2>
                  
                  <div className="max-w-2xl mx-auto space-y-6">
                    <div className="bg-gradient-to-r from-blue-500 to-purple-600 rounded-xl p-6 text-white">
                      <div className="flex items-center gap-3 mb-4">
                        <Wallet size={28} />
                        <h3 className="text-xl font-bold">عنوان المحفظة (TRC20)</h3>
                      </div>
                      <div className="bg-white bg-opacity-20 rounded-lg p-4 mb-4">
                        <p className="text-sm mb-2">قم بالتحويل إلى هذا العنوان:</p>
                        <div className="flex items-center gap-3">
                          <code className="flex-1 bg-black bg-opacity-30 px-3 py-2 rounded text-sm break-all">
                            {WALLET_ADDRESS}
                          </code>
                          <button onClick={() => copyToClipboard(WALLET_ADDRESS)} className="bg-white text-blue-600 p-2 rounded-lg hover:bg-opacity-90">
                            <Copy size={20} />
                          </button>
                        </div>
                      </div>
                      <div className="flex items-center gap-2 text-sm">
                        <AlertCircle size={16} />
                        <span>⚠️ استخدم شبكة TRC20 فقط!</span>
                      </div>
                    </div>

                    <div className="bg-yellow-50 border-r-4 border-yellow-500 p-4 rounded-lg">
                      <p className="text-yellow-800 text-sm">
                        <strong>تعليمات:</strong><br/>
                        1. انسخ عنوان المحفظة<br/>
                        2. أرسل USDT عبر شبكة TRC20<br/>
                        3. احفظ رقم المعاملة<br/>
                        4. عبّئ النموذج أدناه
                      </p>
                    </div>

                    <div className="space-y-4">
                      <div>
                        <label className="block text-gray-700 font-medium mb-2">المبلغ (USDT)</label>
                        <input type="number" value={depositAmount} onChange={(e) => setDepositAmount(e.target.value)} className="w-full px-4 py-3 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:outline-none" placeholder="0.00" />
                      </div>

                      <div>
                        <label className="block text-gray-700 font-medium mb-2">رقم المعاملة (TX Hash)</label>
                        <input type="text" value={txHash} onChange={(e) => setTxHash(e.target.value)} className="w-full px-4 py-3 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:outline-none" placeholder="0x..." dir="ltr" />
                      </div>

                      <div>
                        <label className="block text-gray-700 font-medium mb-2">إثبات التحويل (صورة)</label>
                        {depositProof ? (
                          <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-lg">
                            <FileText size={20} className="text-green-600" />
                            <span className="text-sm">{depositProof.name}</span>
                            <CheckCircle size={20} className="text-green-600" />
                          </div>
                        ) : (
                          <label className="flex items-center justify-center gap-2 p-6 border-2 border-dashed border-gray-300 rounded-lg cursor-pointer hover:bg-gray-50">
                            <Upload size={24} className="text-gray-600" />
                            <span>اضغط لرفع الصورة</span>
                            <input type="file" className="hidden" accept="image/*" onChange={handleDepositProofUpload} />
                          </label>
                        )}
                      </div>

                      <button onClick={submitDeposit} className="w-full bg-gradient-to-r from-blue-600 to-purple-600 text-white py-4 rounded-lg font-bold hover:from-blue-700 hover:to-purple-700 flex items-center justify-center gap-2">
                        <CheckCircle size={20} />
                        إرسال طلب الإيداع
                      </button>
                    </div>
                  </div>
                </div>
              )}

              {activeTab === 'verification' && (
                <div>
                  <h2 className="text-2xl font-bold mb-6">التحقق من الهوية (KYC)</h2>
                  <div className="space-y-6">
                    {['idCard', 'addressProof', 'selfie'].map(docType => {
                      const labels = {
                        idCard: { title: 'بطاقة الهوية', desc: 'صورة واضحة للوثيقة' },
                        addressProof: { title: 'إثبات السكن', desc: 'فاتورة أو كشف (آخر 3 أشهر)' },
                        selfie: { title: 'صورة شخصية', desc: 'صورة سيلفي واضحة' }
                      };
                      return (
                        <div key={docType} className="border-2 border-gray-200 rounded-lg p-6">
                          <div className="flex items-center justify-between mb-4">
                            <div className="flex items-center gap-3">
                              <FileText className="text-blue-600" size={24} />
                              <div>
                                <h3 className="font-bold">{labels[docType].title}</h3>
                                <p className="text-sm text-gray-600">{labels[docType].desc}</p>
                              </div>
                            </div>
                            {getStatusBadge(userDocs[docType].status)}
                          </div>
                          {userDocs[docType].fileName ? (
                            <div className="flex items-center gap-3 p-3 bg-gray-50 rounded">
                              <FileText size={20} />
                              <span className="text-sm">{userDocs[docType].fileName}</span>
                            </div>
                          ) : (
                            <label className="flex items-center justify-center gap-2 p-4 border-2 border-dashed border-gray-300 rounded-lg cursor-pointer hover:bg-gray-50">
                              <Upload size={20} />
                              <span>اضغط لرفع الملف</span>
                              <input type="file" className="hidden" accept="image/*,.pdf" onChange={(e) => handleFileUpload(docType, e)} />
                            </label>
                          )}
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}

              {activeTab === 'history' && (
                <div>
                  <h2 className="text-2xl font-bold mb-6">سجل المعاملات</h2>
                  <div className="space-y-3">
                    {transactions.map(tx => (
                      <div key={tx.id} className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                        <div className="flex items-center gap-4">
                          <div className="p-2 rounded-full bg-green-100">
                            <ArrowUpRight className="text-green-600" size={20} />
                          </div>
                          <div>
                            <p className="font-medium">إيداع USDT</p>
                            <p className="text-sm text-gray-600">{tx.method}</p>
                            <p className="text-xs text-gray-500">TX: {tx.txHash}</p>
                          </div>
                        </div>
                        <div className="text-left">
                          <p className="font-bold text-green-600">+${tx.amount.toLocaleString()}</p>
                          <p className="text-sm text-gray-600">{tx.date}</p>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </>
          ) : (
            <>
              {activeTab === 'admin-deposits' && (
                <div>
                  <h2 className="text-2xl font-bold mb-6">طلبات الإيداع المعلقة</h2>
                  <div className="space-y-4">
                    {pendingDeposits.filter(d => d.status === 'pending').map(deposit => (
                      <div key={deposit.id} className="border-2 border-yellow-300 bg-yellow-50 rounded-lg p-6">
                        <div className="flex items-center justify-between mb-4">
                          <div>
                            <h3 className="text-lg font-bold">{deposit.userName}</h3>
                            <p className="text-2xl font-bold text-blue-600">${deposit.amount.toLocaleString()}</p>
                          </div>
                          {getStatusBadge(deposit.status)}
                        </div>
                        <div className="space-y-2 mb-4 text-sm">
                          <p><strong>الشبكة:</strong> {deposit.network}</p>
                          <p><strong>TX:</strong> <code className="bg-gray-200 px-2 py-1 rounded text-xs">{deposit.txHash}</code></p>
                          <p><strong>التاريخ:</strong> {deposit.date}</p>
                        </div>
                        <div className="flex gap-3">
                          <button onClick={() => approveDeposit(deposit.id)} className="flex items-center gap-2 px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700">
                            <Check size={20} /> موافقة
                          </button>
                          <button onClick={() => rejectDeposit(deposit.id)} className="flex items-center gap-2 px-6 py-3 bg-red-600 text-white rounded-lg hover:bg-red-700">
                            <X size={20} /> رفض
                          </button>
                          <button className="flex items-center gap-2 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
                            <Eye size={20} /> عرض
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {activeTab === 'admin-verify' && (
                <div>
                  <h2 className="text-2xl font-bold mb-6">مراجعة الوثائق</h2>
                  <div className="space-y-6">
                    {allUsers.filter(u => u.accountStatus === 'pending').map(user => (
                      <div key={user.id} className="border-2 border-gray-200 rounded-lg p-6">
                        <div className="flex items-center justify-between mb-4">
                          <div>
                            <h3 className="text-xl font-bold">{user.name}</h3>
                            <p className="text-gray-600">{user.email}</p>
                          </div>
                          {getStatusBadge(user.accountStatus)}
                        </div>
                        <div className="space-y-4">
                          {Object.entries(user.docs).map(([docType, doc]) => (
                            <div key={docType} className="bg-gray-50 rounded-lg p-4">
                              <div className="flex items-center justify-between mb-3">
                                <div className="flex items-center gap-2">
                                  <FileText size={20} className="text-blue-600" />
                                  <div>
                                    <p className="font-bold text-sm">{docType === 'idCard' ? 'بطاقة الهوية' : docType === 'addressProof' ? 'إثبات السكن' : 'صورة شخصية'}</p>
                                    <p className="text-xs text-gray-600">{doc.fileName}</p>
                                  </div>
                                </div>
                                {getStatusBadge(doc.status)}
                              </div>
                              {doc.status === 'pending' && (
                                <div className="flex gap-3">
                                  <button onClick={() => approveDocument(user.id, docType)} className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg text-sm">
                                    <Check size={16} /> موافقة
                                  </button>
                                  <button onClick={() => rejectDocument(user.id, docType)} className="flex items-center gap-2 px-4 py-2 bg-red-600 text-white rounded-lg text-sm">
                                    <X size={16} /> رفض
                                  </button>
                                </div>
                              )}
                            </div>
                          ))}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {activeTab === 'admin-users' && (
                <div>
                  <h2 className="text-2xl font-bold mb-6">المستخدمين</h2>
                  <div className="space-y-4">
                    {allUsers.map(user => (
                      <div key={user.id} className="flex items-center justify-between p-4 border-2 border-gray-200 rounded-lg">
                        <div>
                          <p className="font-bold">{user.name}</p>
                          <p className="text-sm text-gray-600">{user.email}</p>
                        </div>
                        {getStatusBadge(user.accountStatus)}
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );
}
